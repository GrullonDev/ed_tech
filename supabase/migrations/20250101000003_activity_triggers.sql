-- Triggers que generan el "Feed de Actividad de la Tribu"
-- (activity_events) automáticamente desde el servidor. Reemplazan las
-- llamadas a _pushActivityEvent() que hoy viven en HomeLogic (Dart): la
-- ventaja de moverlas a Postgres es que el feed queda correcto sin importar
-- desde qué dispositivo o cliente llegó el check-in, y ningún cliente puede
-- falsificar un evento (no hay policy de INSERT para activity_events).
-- Todas corren como SECURITY DEFINER para poder escribir en activity_events
-- pese a que los clientes no tienen permiso directo de insertar ahí.

-- ---------------------------------------------------------------------
-- fn_maybe_grant_shield: otorga un escudo la primera vez que la racha de
-- un miembro cruza cada hito (7/21/30/50/100), espejo de
-- HomeLogic._grantFreezeIfMilestoneReached.
-- ---------------------------------------------------------------------
create or replace function public.fn_maybe_grant_shield(
  p_circle_id uuid,
  p_user_id uuid,
  p_streak int,
  p_circle_name text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_milestone int;
begin
  foreach v_milestone in array array[7, 21, 30, 50, 100]
  loop
    if p_streak < v_milestone then
      continue;
    end if;

    insert into public.streak_shield_grants (circle_id, user_id, milestone_days)
    values (p_circle_id, p_user_id, v_milestone)
    on conflict (circle_id, user_id, milestone_days) do nothing;

    if found then
      insert into public.activity_events (circle_id, actor_id, event_type, emoji, message, payload)
      values (
        p_circle_id, p_user_id, 'milestone', '🏆',
        format('%s alcanzó %s días de racha — ¡ganaste un Escudo de Racha! 🛡️', p_circle_name, v_milestone),
        jsonb_build_object('milestone_days', v_milestone)
      );
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- trg_check_in_activity: al insertar un check-in real, publica el evento
-- de check-in, evalúa si se gana un escudo y detecta "Círculo Perfecto"
-- (todos los miembros de un círculo con >1 miembro hicieron check-in hoy).
-- Espejo de lo que HomeLogic.toggleCheckIn hacía solo para el dispositivo
-- local.
-- ---------------------------------------------------------------------
create or replace function public.trg_check_in_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_circle_name text;
  v_streak int;
  v_total_members int;
  v_completed_today int;
begin
  select username into v_username from public.profiles where id = new.user_id;
  select name into v_circle_name from public.circles where id = new.circle_id;
  v_streak := public.fn_circle_streak_days(new.circle_id, new.user_id);

  insert into public.activity_events (circle_id, actor_id, event_type, emoji, message, payload)
  values (
    new.circle_id, new.user_id, 'check_in', '🔥',
    format('%s completó "%s" — racha de %s días.', v_username, v_circle_name, v_streak),
    jsonb_build_object('streak_days', v_streak)
  );

  perform public.fn_maybe_grant_shield(new.circle_id, new.user_id, v_streak, v_circle_name);

  select count(*) into v_total_members
    from public.circle_members where circle_id = new.circle_id;
  select count(distinct user_id) into v_completed_today
    from public.check_ins where circle_id = new.circle_id and check_in_date = new.check_in_date;

  if v_total_members > 1 and v_completed_today = v_total_members then
    insert into public.activity_events (circle_id, actor_id, event_type, emoji, message)
    values (
      new.circle_id, null, 'perfect_circle', '✨',
      format('¡"%s" logró el Círculo Perfecto de hoy!', v_circle_name)
    );
  end if;

  return new;
end;
$$;

create trigger on_check_in_insert
  after insert on public.check_ins
  for each row execute function public.trg_check_in_activity();

-- ---------------------------------------------------------------------
-- trg_circle_owner_membership: al crear un círculo, inscribe
-- automáticamente al dueño como miembro (role 'owner'). Necesario porque
-- las policies de SELECT de circles/circle_members exigen ser miembro (ver
-- 20250101000004_rls.sql), y el círculo recién creado todavía no tiene
-- ninguna fila en circle_members.
-- ---------------------------------------------------------------------
create or replace function public.trg_circle_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.circle_members (circle_id, user_id, role)
  values (new.id, new.owner_id, 'owner');
  return new;
end;
$$;

create trigger on_circle_insert
  after insert on public.circles
  for each row execute function public.trg_circle_owner_membership();

-- ---------------------------------------------------------------------
-- trg_member_joined_activity: espejo de
-- HomeLogic.addMemberToCircle -> "%s se unió a %s.". Se omite para el
-- propio dueño (evento redundante con la creación del círculo).
-- ---------------------------------------------------------------------
create or replace function public.trg_member_joined_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_circle_name text;
  v_is_owner boolean;
begin
  select (owner_id = new.user_id) into v_is_owner
    from public.circles where id = new.circle_id;
  if v_is_owner then
    return new;
  end if;

  select username into v_username from public.profiles where id = new.user_id;
  select name into v_circle_name from public.circles where id = new.circle_id;

  insert into public.activity_events (circle_id, actor_id, event_type, emoji, message)
  values (
    new.circle_id, new.user_id, 'member_joined', '🎉',
    format('%s se unió a "%s".', v_username, v_circle_name)
  );
  return new;
end;
$$;

create trigger on_circle_member_insert
  after insert on public.circle_members
  for each row execute function public.trg_member_joined_activity();

-- ---------------------------------------------------------------------
-- trg_shield_used_activity: espejo del evento que HomeLogic emitía al
-- consumir un escudo automáticamente (_applyPendingStreakFreezes).
-- ---------------------------------------------------------------------
create or replace function public.trg_shield_used_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle_name text;
begin
  select name into v_circle_name from public.circles where id = new.circle_id;
  insert into public.activity_events (circle_id, actor_id, event_type, emoji, message)
  values (
    new.circle_id, new.user_id, 'shield_used', '🛡️',
    format('%s usó un Escudo de Racha para no perder la cadena.', v_circle_name)
  );
  return new;
end;
$$;

create trigger on_streak_shield_use_insert
  after insert on public.streak_shield_uses
  for each row execute function public.trg_shield_used_activity();

-- ---------------------------------------------------------------------
-- trg_ally_status_activity: espejo de HomeLogic.acceptAllyRequest ->
-- "Ahora eres aliado de %s.". Solo dispara al pasar a 'accepted'.
-- ---------------------------------------------------------------------
create or replace function public.trg_ally_status_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_from_username text;
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    select username into v_from_username from public.profiles where id = new.from_user_id;
    insert into public.activity_events (circle_id, actor_id, event_type, emoji, message)
    values (
      null, new.to_user_id, 'ally_accepted', '🕊️',
      format('Ahora eres aliado de %s.', v_from_username)
    );
  end if;
  return new;
end;
$$;

create trigger on_ally_request_update
  after update on public.ally_requests
  for each row execute function public.trg_ally_status_activity();
