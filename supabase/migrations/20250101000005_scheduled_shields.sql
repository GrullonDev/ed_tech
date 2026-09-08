-- Job diario que aplica escudos pendientes: espejo de
-- HomeLogic._applyPendingStreakFreezes(), que en Dart corría cada vez que
-- se abría la app. En el backend no podemos depender de que alguien abra
-- la app, así que esto corre como cron diario en el propio Postgres.
--
-- Requiere la extensión pg_cron, disponible en Supabase habilitándola
-- desde Database → Extensions (no se puede activar por SQL en el plan
-- gratuito gestionado; si el proyecto no la tiene disponible, se puede
-- invocar fn_apply_pending_shields() desde una Supabase Edge Function con
-- un cron trigger en su lugar — misma función, distinto disparador).

create or replace function public.fn_apply_pending_shields()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_yesterday date := current_date - 1;
  v_day_before date := current_date - 2;
begin
  for r in
    select cm.circle_id, cm.user_id
    from public.circle_members cm
    where
      -- Ayer no hubo check-in real...
      not exists (
        select 1 from public.check_ins ci
        where ci.circle_id = cm.circle_id and ci.user_id = cm.user_id
          and ci.check_in_date = v_yesterday
      )
      -- ...y todavía no se cubrió con un escudo...
      and not exists (
        select 1 from public.streak_shield_uses su
        where su.circle_id = cm.circle_id and su.user_id = cm.user_id
          and su.covered_date = v_yesterday
      )
      -- ...pero sí traía una racha activa hasta anteayer (real o puenteada).
      and (
        exists (
          select 1 from public.check_ins ci
          where ci.circle_id = cm.circle_id and ci.user_id = cm.user_id
            and ci.check_in_date = v_day_before
        )
        or exists (
          select 1 from public.streak_shield_uses su
          where su.circle_id = cm.circle_id and su.user_id = cm.user_id
            and su.covered_date = v_day_before
        )
      )
  loop
    if public.fn_circle_freezes_available(r.circle_id, r.user_id) > 0 then
      insert into public.streak_shield_uses (circle_id, user_id, covered_date)
      values (r.circle_id, r.user_id, v_yesterday)
      on conflict do nothing;
      -- El insert dispara on_streak_shield_use_insert, que publica el
      -- evento en activity_events (ver 20250101000003_activity_triggers.sql).
    end if;
  end loop;
end;
$$;

-- Descomentar tras habilitar pg_cron en el proyecto de Supabase
-- (Database → Extensions → pg_cron):
--
-- select cron.schedule(
--   'apply-pending-streak-shields',
--   '5 0 * * *', -- 00:05 UTC todos los días
--   $$select public.fn_apply_pending_shields()$$
-- );
