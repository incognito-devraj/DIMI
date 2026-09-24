-- DIMI tombstone-retention verification.
--
-- Run in the Supabase SQL Editor after applying the migration.  These are
-- assertions about the production function's safety predicates and cutoff;
-- no production rows are modified by this script.

do $$
declare
  function_source text;
begin
  select lower(pg_get_functiondef('public.dimi_purge_expired_tombstones()'::regprocedure))
    into function_source;

  if function_source not like '%deleted_at is not null%' then
    raise exception 'Retention function lacks the tombstone-only predicate';
  end if;
  if function_source not like '%deleted_at < cutoff%' then
    raise exception 'Retention function does not use the 30-day deleted_at cutoff';
  end if;
  if function_source not like '%interval ''30 days''%' then
    raise exception 'Retention function does not use a 30-day database interval';
  end if;
  if function_source not like '%dim_reminders%' or
     function_source not like '%dim_youtube_videos%' or
     function_source not like '%dim_tasks%' or
     function_source not like '%dim_youtube_playlists%' then
    raise exception 'Retention function is missing a dependency table';
  end if;
  if function_source not like '%not exists (%' then
    raise exception 'Retention function lacks parent-child safety guards';
  end if;
  if function_source not like '%security definer%' then
    raise exception 'Retention function is not server-side secured';
  end if;
end $$;

-- Expected behavior for a live fixture run:
--   deleted_at = now() - interval '29 days'       => retained
--   deleted_at = now() - interval '30 days'       => eligible
--   deleted_at = now() - interval '31 days'       => eligible
--   deleted_at is null                             => never eligible
-- A parent with any remaining child row must also remain.
