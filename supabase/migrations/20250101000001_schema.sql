-- Esquema base de Racha Tribu: perfiles, círculos, membresías y check-ins.
--
-- Mapea 1:1 los modelos Dart actuales (lib/core/model/*) a tablas
-- relacionales. Todo lo que hoy es "derivado" en Dart (streakDays,
-- longestStreakDays, constancyDropsEarned) sigue siendo derivado aquí: no
-- hay columnas de contador que se puedan desincronizar, solo funciones
-- (ver 20250101000002_streak_functions.sql) que las calculan al vuelo desde
-- check_ins y los ledgers de escudos.
create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- profiles: 1:1 con auth.users. Sustituye a AppUser. playerId desaparece:
-- el propio auth.uid() (= profiles.id) es el identificador que viaja en el
-- QR de "Invocar por QR" (ver MIGRATION_PLAN.md).
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique check (char_length(username) between 1 and 40),
  member_since timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- circles: sustituye a HabitCircle (sin los campos derivados/simulados:
-- members/checkIns pasan a sus propias tablas). invite_code reemplaza la
-- invitación puramente local de "Invitar a un amigo" por un código real
-- que otro usuario puede canjear.
-- ---------------------------------------------------------------------
create table public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  category text not null default 'General',
  owner_id uuid not null references public.profiles (id) on delete cascade,
  invite_code text not null unique default encode(gen_random_bytes(5), 'hex'),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- circle_members: sustituye a HabitCircle.members (List<String> de nombres
-- locales) por una relación real usuario-círculo.
-- ---------------------------------------------------------------------
create table public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

create index circle_members_user_id_idx on public.circle_members (user_id);

-- ---------------------------------------------------------------------
-- check_ins: sustituye a HabitCircle.checkIns (List<CheckIn>). Único punto
-- de verdad para racha, gotas y progreso diario de cada miembro.
-- ---------------------------------------------------------------------
create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  check_in_date date not null,
  created_at timestamptz not null default now(),
  unique (circle_id, user_id, check_in_date)
);

create index check_ins_circle_date_idx on public.check_ins (circle_id, check_in_date);
create index check_ins_user_date_idx on public.check_ins (user_id, check_in_date);

-- ---------------------------------------------------------------------
-- streak_shield_grants / streak_shield_uses: ledger de "Escudos de Racha"
-- en vez de un contador mutable (HabitCircle.freezesAvailable). Igual que
-- en Dart, freezesAvailable = grants - uses; se deriva, nunca se guarda
-- directamente, para que no se pueda duplicar ni perder un escudo por una
-- carrera entre dos dispositivos escribiendo al mismo tiempo.
-- ---------------------------------------------------------------------
create table public.streak_shield_grants (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  milestone_days int not null check (milestone_days in (7, 21, 30, 50, 100)),
  granted_at timestamptz not null default now(),
  unique (circle_id, user_id, milestone_days)
);

create table public.streak_shield_uses (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  covered_date date not null,
  used_at timestamptz not null default now(),
  unique (circle_id, user_id, covered_date)
);

-- ---------------------------------------------------------------------
-- ally_requests: sustituye a AllyRequest + la lista local "allies". El
-- estado accepted/rejected reemplaza el flujo simulado de aceptar/rechazar.
-- ---------------------------------------------------------------------
create table public.ally_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles (id) on delete cascade,
  to_user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (from_user_id, to_user_id),
  check (from_user_id <> to_user_id)
);

create index ally_requests_to_user_idx on public.ally_requests (to_user_id, status);

-- Vista de conveniencia: relación de aliados aceptados, en ambos sentidos.
-- security_invoker hace que respete las políticas RLS de ally_requests con
-- el usuario que consulta la vista, no con el dueño de la vista.
create view public.allies
  with (security_invoker = true) as
    select from_user_id as user_id, to_user_id as ally_id, created_at
    from public.ally_requests
    where status = 'accepted'
  union all
    select to_user_id as user_id, from_user_id as ally_id, created_at
    from public.ally_requests
    where status = 'accepted';

-- ---------------------------------------------------------------------
-- activity_events: sustituye a ActivityEvent + activity_feed_box. Solo se
-- escribe desde funciones/triggers SECURITY DEFINER (ver
-- 20250101000003_activity_triggers.sql), nunca directo desde el cliente,
-- para que el feed no se pueda falsear.
-- ---------------------------------------------------------------------
create type public.activity_event_type as enum (
  'check_in',
  'milestone',
  'shield_granted',
  'shield_used',
  'member_joined',
  'perfect_circle',
  'ally_accepted'
);

create table public.activity_events (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid references public.circles (id) on delete cascade,
  actor_id uuid references public.profiles (id) on delete set null,
  event_type public.activity_event_type not null,
  emoji text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index activity_events_circle_created_idx
  on public.activity_events (circle_id, created_at desc);
