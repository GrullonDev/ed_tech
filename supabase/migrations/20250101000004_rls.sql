-- Row Level Security: cada tabla queda cerrada por defecto y se abre solo
-- con las policies de abajo. Se usa una función helper security definer
-- (is_circle_member) en vez de subconsultas directas sobre
-- circle_members dentro de sus propias policies, para evitar el problema
-- clásico de RLS recursiva sobre la misma tabla.

create or replace function public.is_circle_member(p_circle_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.circle_members
    where circle_id = p_circle_id and user_id = p_user_id
  );
$$;

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;

-- Los usernames no son sensibles (ya viajan hoy en el QR de "Invocar por
-- QR" y en el leaderboard del Ágora): cualquier usuario autenticado puede
-- leer cualquier perfil, para poder mostrar nombres en círculos/feed/QR
-- antes de ser miembro o aliado de nadie.
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_insert_self"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_self"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- circles
-- ---------------------------------------------------------------------
alter table public.circles enable row level security;

create policy "circles_select_members"
  on public.circles for select
  to authenticated
  using (public.is_circle_member(id));

create policy "circles_insert_as_owner"
  on public.circles for insert
  to authenticated
  with check (auth.uid() = owner_id);

create policy "circles_update_owner"
  on public.circles for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "circles_delete_owner"
  on public.circles for delete
  to authenticated
  using (auth.uid() = owner_id);

-- ---------------------------------------------------------------------
-- circle_members
-- ---------------------------------------------------------------------
alter table public.circle_members enable row level security;

create policy "circle_members_select_fellow_members"
  on public.circle_members for select
  to authenticated
  using (public.is_circle_member(circle_id));

-- Unirse a un círculo requiere conocer su invite_code (canjeado por la app
-- antes de este insert, ver MIGRATION_PLAN.md); el propio usuario se
-- inscribe a sí mismo, nunca a otro.
create policy "circle_members_insert_self"
  on public.circle_members for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "circle_members_delete_self_or_owner"
  on public.circle_members for delete
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- check_ins
-- ---------------------------------------------------------------------
alter table public.check_ins enable row level security;

create policy "check_ins_select_circle_members"
  on public.check_ins for select
  to authenticated
  using (public.is_circle_member(circle_id));

create policy "check_ins_insert_self"
  on public.check_ins for insert
  to authenticated
  with check (auth.uid() = user_id and public.is_circle_member(circle_id));

create policy "check_ins_delete_self"
  on public.check_ins for delete
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- streak_shield_grants / streak_shield_uses: de solo lectura para el
-- cliente. Sin policies de insert/update/delete, así que RLS bloquea toda
-- escritura directa — solo las funciones SECURITY DEFINER de
-- 20250101000003_activity_triggers.sql pueden escribir ahí.
-- ---------------------------------------------------------------------
alter table public.streak_shield_grants enable row level security;

create policy "streak_shield_grants_select_members"
  on public.streak_shield_grants for select
  to authenticated
  using (public.is_circle_member(circle_id));

alter table public.streak_shield_uses enable row level security;

create policy "streak_shield_uses_select_members"
  on public.streak_shield_uses for select
  to authenticated
  using (public.is_circle_member(circle_id));

-- ---------------------------------------------------------------------
-- ally_requests
-- ---------------------------------------------------------------------
alter table public.ally_requests enable row level security;

create policy "ally_requests_select_own"
  on public.ally_requests for select
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

create policy "ally_requests_insert_as_sender"
  on public.ally_requests for insert
  to authenticated
  with check (auth.uid() = from_user_id);

-- Solo el receptor puede aceptar/rechazar; el remitente no puede
-- autoaprobar su propia solicitud.
create policy "ally_requests_update_as_receiver"
  on public.ally_requests for update
  to authenticated
  using (auth.uid() = to_user_id)
  with check (auth.uid() = to_user_id);

-- ---------------------------------------------------------------------
-- activity_events: de solo lectura para el cliente (ver comentario de
-- streak_shield_* arriba — mismo motivo: el feed no se puede falsear).
-- ---------------------------------------------------------------------
alter table public.activity_events enable row level security;

create policy "activity_events_select_relevant"
  on public.activity_events for select
  to authenticated
  using (
    (circle_id is not null and public.is_circle_member(circle_id))
    or (circle_id is null and actor_id = auth.uid())
  );
