-- Funciones que replican, 1:1, la lógica de HabitCircle en Dart
-- (lib/core/model/habit_circle.dart): streakDays, longestStreakDays y
-- constancyDropsEarned. Se implementan como funciones PL/pgSQL (no como
-- columnas) por la misma razón que en Dart son getters: deben ser
-- imposibles de desincronizar de check_ins/streak_shield_uses.

-- ---------------------------------------------------------------------
-- fn_circle_streak_days: espejo exacto de HabitCircle.streakDays. Cuenta
-- hacia atrás desde hoy (o ayer si hoy aún no tiene check-in) y trata un
-- streak_shield_uses.covered_date como puente que no rompe la cadena pero
-- tampoco suma un día.
-- ---------------------------------------------------------------------
create or replace function public.fn_circle_streak_days(p_circle_id uuid, p_user_id uuid)
returns int
language plpgsql
stable
as $$
declare
  v_expected date;
  v_streak int := 0;
begin
  if exists (
    select 1 from public.check_ins
    where circle_id = p_circle_id and user_id = p_user_id and check_in_date = current_date
  ) then
    v_expected := current_date;
  else
    v_expected := current_date - 1;
  end if;

  loop
    if exists (
      select 1 from public.check_ins
      where circle_id = p_circle_id and user_id = p_user_id and check_in_date = v_expected
    ) then
      v_streak := v_streak + 1;
    elsif exists (
      select 1 from public.streak_shield_uses
      where circle_id = p_circle_id and user_id = p_user_id and covered_date = v_expected
    ) then
      -- Puente: la racha sigue viva pero este día no suma.
      null;
    else
      exit;
    end if;
    v_expected := v_expected - 1;
  end loop;

  return v_streak;
end;
$$;

-- ---------------------------------------------------------------------
-- fn_circle_longest_streak_days: espejo de HabitCircle.longestStreakDays
-- (récord histórico, sin considerar escudos — igual que en Dart hoy).
-- Implementado con la técnica "gaps and islands" vía funciones de ventana.
-- ---------------------------------------------------------------------
create or replace function public.fn_circle_longest_streak_days(p_circle_id uuid, p_user_id uuid)
returns int
language sql
stable
as $$
  with ordered as (
    select
      check_in_date,
      row_number() over (order by check_in_date) as rn
    from public.check_ins
    where circle_id = p_circle_id and user_id = p_user_id
  ),
  islands as (
    select check_in_date - (rn * interval '1 day') as island_key
    from ordered
  )
  select coalesce(max(island_size), 0)
  from (
    select count(*) as island_size from islands group by island_key
  ) sizes;
$$;

-- ---------------------------------------------------------------------
-- fn_circle_drops_earned: espejo de HabitCircle.constancyDropsEarned. El
-- multiplicador crece con la racha vigente el día de cada check-in real
-- (10 gotas en racha 1-6, x1.5 desde el día 7, x2 desde el día 21, x3
-- desde el día 50). Un día cubierto por un escudo mantiene el conteo de
-- racha para el multiplicador pero no gana gotas propias.
-- ---------------------------------------------------------------------
create or replace function public.fn_circle_drops_earned(p_circle_id uuid, p_user_id uuid)
returns int
language plpgsql
stable
as $$
declare
  v_day date;
  v_prev date;
  v_streak int := 0;
  v_drops int := 0;
  v_gap int;
  v_bridged boolean;
begin
  for v_day in
    select check_in_date from public.check_ins
    where circle_id = p_circle_id and user_id = p_user_id
    order by check_in_date
  loop
    if v_prev is null then
      v_streak := 1;
    else
      v_gap := v_day - v_prev;
      v_bridged := v_gap = 2 and exists (
        select 1 from public.streak_shield_uses
        where circle_id = p_circle_id and user_id = p_user_id
          and covered_date = v_prev + 1
      );
      if v_gap = 1 or v_bridged then
        v_streak := v_streak + 1;
      else
        v_streak := 1;
      end if;
    end if;

    v_drops := v_drops + case
      when v_streak >= 50 then 30
      when v_streak >= 21 then 20
      when v_streak >= 7 then 15
      else 10
    end;
    v_prev := v_day;
  end loop;

  return v_drops;
end;
$$;

-- ---------------------------------------------------------------------
-- fn_circle_freezes_available: freezesAvailable derivado (grants - uses),
-- espejo del cálculo que antes vivía como campo mutable en Dart.
-- ---------------------------------------------------------------------
create or replace function public.fn_circle_freezes_available(p_circle_id uuid, p_user_id uuid)
returns int
language sql
stable
as $$
  select
    (select count(*) from public.streak_shield_grants
      where circle_id = p_circle_id and user_id = p_user_id)
    -
    (select count(*) from public.streak_shield_uses
      where circle_id = p_circle_id and user_id = p_user_id);
$$;

-- ---------------------------------------------------------------------
-- circle_member_stats: vista de conveniencia para que el cliente pida en
-- una sola consulta lo que en Dart eran varios getters de HabitCircle.
-- ---------------------------------------------------------------------
create view public.circle_member_stats
  with (security_invoker = true) as
  select
    cm.circle_id,
    cm.user_id,
    public.fn_circle_streak_days(cm.circle_id, cm.user_id) as streak_days,
    public.fn_circle_longest_streak_days(cm.circle_id, cm.user_id) as longest_streak_days,
    public.fn_circle_drops_earned(cm.circle_id, cm.user_id) as drops_earned,
    public.fn_circle_freezes_available(cm.circle_id, cm.user_id) as freezes_available,
    exists (
      select 1 from public.check_ins ci
      where ci.circle_id = cm.circle_id and ci.user_id = cm.user_id and ci.check_in_date = current_date
    ) as checked_in_today
  from public.circle_members cm;
