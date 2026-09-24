-- DIMI: server-side 30-day tombstone retention.
--
-- This function is intentionally not exposed to mobile clients.  It is meant
-- to be called by a trusted Postgres scheduler after pg_cron is enabled.
-- The cutoff uses the database transaction clock, never a device timestamp.

create or replace function public.dimi_purge_expired_tombstones()
returns table (table_name text, deleted_rows bigint)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  cutoff timestamptz := now() - interval '30 days';
  count_deleted bigint;
begin
  -- Children first.  Only already-tombstoned rows are ever candidates.
  with candidates as (
    select id from public.dim_reminders
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_reminders r using candidates c where r.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_reminders';
  deleted_rows := count_deleted;
  return next;

  with candidates as (
    select id from public.dim_youtube_videos
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_youtube_videos v using candidates c where v.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_youtube_videos';
  deleted_rows := count_deleted;
  return next;

  -- A parent with any remaining reminder is retained.  This prevents an
  -- active child from being removed by the task foreign-key action.
  with candidates as (
    select task_row.id from public.dim_tasks task_row
     where task_row.deleted_at is not null and task_row.deleted_at < cutoff
       and not exists (
       select 1
       from public.dim_reminders as reminder_row
       where reminder_row.task_id = task_row.id
         and reminder_row.user_id = task_row.user_id
     ) order by task_row.deleted_at, task_row.id limit 1000
  )
  delete from public.dim_tasks t using candidates c where t.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_tasks';
  deleted_rows := count_deleted;
  return next;

  -- A playlist with any remaining video is retained.  This prevents an
  -- active child from being removed by the playlist cascade.
  with candidates as (
    select playlist_row.id from public.dim_youtube_playlists playlist_row
     where playlist_row.deleted_at is not null and playlist_row.deleted_at < cutoff
       and not exists (
       select 1
       from public.dim_youtube_videos as video_row
       where video_row.playlist_id = playlist_row.id
         and video_row.user_id = playlist_row.user_id
     ) order by playlist_row.deleted_at, playlist_row.id limit 1000
  )
  delete from public.dim_youtube_playlists p using candidates c where p.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_youtube_playlists';
  deleted_rows := count_deleted;
  return next;

  with candidates as (
    select id from public.dim_notes
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_notes n using candidates c where n.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_notes';
  deleted_rows := count_deleted;
  return next;

  with candidates as (
    select id from public.dim_money_transactions
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_money_transactions m using candidates c where m.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_money_transactions';
  deleted_rows := count_deleted;
  return next;

  with candidates as (
    select id from public.dim_merchant_category_rules
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_merchant_category_rules r using candidates c where r.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_merchant_category_rules';
  deleted_rows := count_deleted;
  return next;

  with candidates as (
    select id from public.dim_profile_data
     where deleted_at is not null and deleted_at < cutoff
     order by deleted_at, id limit 1000
  )
  delete from public.dim_profile_data p using candidates c where p.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_profile_data';
  deleted_rows := count_deleted;
  return next;

  -- Accounts are last and are deleted only when no dependent row remains.
  -- In particular, an active dependent row prevents account deletion.
  with candidates as (
    select account_row.id from public.dim_accounts account_row
     where account_row.deleted_at is not null and account_row.deleted_at < cutoff
     and not exists (select 1 from public.dim_profile_data p where p.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_tasks t where t.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_reminders r where r.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_notes n where n.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_money_transactions m where m.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_merchant_category_rules c where c.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_youtube_playlists p where p.user_id = account_row.user_id)
     and not exists (select 1 from public.dim_youtube_videos v where v.user_id = account_row.user_id)
     order by account_row.deleted_at, account_row.id limit 1000
  )
  delete from public.dim_accounts a using candidates c where a.id = c.id;
  get diagnostics count_deleted = row_count;
  table_name := 'dim_accounts';
  deleted_rows := count_deleted;
  return next;
end;
$$;

-- No authenticated, anonymous, or public client may invoke permanent cleanup.
revoke all on function public.dimi_purge_expired_tombstones() from public;
revoke all on function public.dimi_purge_expired_tombstones() from anon;
revoke all on function public.dimi_purge_expired_tombstones() from authenticated;
