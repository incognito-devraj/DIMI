-- DIMI RLS isolation test.
--
-- Run only in Supabase SQL Editor with two dedicated Auth test users.
-- Replace the placeholders below before running. The transaction is rolled
-- back at the end; no test rows remain.

begin;

create temp table _dimi_rls_users (
  user_a uuid not null,
  user_b uuid not null
);

insert into _dimi_rls_users values (
  'cb6675b4-bb8b-45cf-bdb9-23e46ed7c750'::uuid,
  '1edbe370-88d8-478d-b01b-a7d3195d4c9f'::uuid
);

do $$
declare
  a uuid;
  b uuid;
begin
  select user_a, user_b into a, b from _dimi_rls_users;

  if not exists (select 1 from auth.users where id = a) then
    raise exception 'User A does not exist in auth.users';
  end if;

  if not exists (select 1 from auth.users where id = b) then
    raise exception 'User B does not exist in auth.users';
  end if;

  if a = b then
    raise exception 'User A and User B must be different';
  end if;
end $$;

create temp table _dimi_rls_rows as
select
  gen_random_uuid() as account_a,
  gen_random_uuid() as account_b,
  gen_random_uuid() as profile_a,
  gen_random_uuid() as profile_b,
  gen_random_uuid() as task_a,
  gen_random_uuid() as task_b,
  gen_random_uuid() as reminder_a,
  gen_random_uuid() as reminder_b,
  gen_random_uuid() as note_a,
  gen_random_uuid() as note_b,
  gen_random_uuid() as transaction_a,
  gen_random_uuid() as transaction_b,
  gen_random_uuid() as rule_a,
  gen_random_uuid() as rule_b,
  gen_random_uuid() as playlist_a,
  gen_random_uuid() as playlist_b,
  gen_random_uuid() as video_a,
  gen_random_uuid() as video_b;

create temp table _dimi_rls_results (
  test_name text,
  passed boolean
);

create or replace function pg_temp.record_result(
  name text,
  result boolean
)
returns void
language plpgsql
as $$
begin
  insert into _dimi_rls_results values (name, result);
end;
$$;

-- Seed only temporary rows. The final ROLLBACK removes them.
insert into public.dim_accounts (id, user_id, display_name)
select account_a, user_a, 'RLS Test A'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_accounts (id, user_id, display_name)
select account_b, user_b, 'RLS Test B'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_profile_data (id, user_id)
select profile_a, user_a
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_profile_data (id, user_id)
select profile_b, user_b
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_tasks
  (id, user_id, title, category, local_date)
select task_a, user_a, 'RLS Task A', 'Test', current_date
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_tasks
  (id, user_id, title, category, local_date)
select task_b, user_b, 'RLS Task B', 'Test', current_date
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_reminders
  (id, user_id, task_id, title, due_at)
select reminder_a, user_a, task_a, 'RLS Reminder A', now()
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_reminders
  (id, user_id, task_id, title, due_at)
select reminder_b, user_b, task_b, 'RLS Reminder B', now()
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_notes
  (id, user_id, title, content, category)
select note_a, user_a, 'RLS Note A', 'Temporary test row', 'Test'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_notes
  (id, user_id, title, content, category)
select note_b, user_b, 'RLS Note B', 'Temporary test row', 'Test'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_money_transactions
  (id, user_id, type, amount_minor, category, occurred_on)
select transaction_a, user_a, 'lent', 100, 'Test', now()
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_money_transactions
  (id, user_id, type, amount_minor, category, occurred_on)
select transaction_b, user_b, 'borrowed', 200, 'Test', now()
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_merchant_category_rules
  (id, user_id, merchant_identity, category)
select rule_a, user_a, 'rls-test-a', 'Test'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_merchant_category_rules
  (id, user_id, merchant_identity, category)
select rule_b, user_b, 'rls-test-b', 'Test'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_youtube_playlists
  (id, user_id, youtube_playlist_id, title)
select playlist_a, user_a, 'rls-test-playlist-a', 'RLS Playlist A'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_youtube_playlists
  (id, user_id, youtube_playlist_id, title)
select playlist_b, user_b, 'rls-test-playlist-b', 'RLS Playlist B'
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_youtube_videos
  (id, user_id, playlist_id, youtube_video_id, title, position)
select video_a, user_a, playlist_a, 'rls-test-video-a', 'RLS Video A', 0
from _dimi_rls_rows, _dimi_rls_users;

insert into public.dim_youtube_videos
  (id, user_id, playlist_id, youtube_video_id, title, position)
select video_b, user_b, playlist_b, 'rls-test-video-b', 'RLS Video B', 0
from _dimi_rls_rows, _dimi_rls_users;

-- Allow the authenticated role to reach the tables so the RLS policies,
-- rather than table-privilege errors, determine every test result.
grant select, insert, update, delete on table public.dim_accounts to authenticated;
grant select, insert, update, delete on table public.dim_profile_data to authenticated;
grant select, insert, update, delete on table public.dim_tasks to authenticated;
grant select, insert, update, delete on table public.dim_reminders to authenticated;
grant select, insert, update, delete on table public.dim_notes to authenticated;
grant select, insert, update, delete on table public.dim_money_transactions to authenticated;
grant select, insert, update, delete on table public.dim_merchant_category_rules to authenticated;
grant select, insert, update, delete on table public.dim_youtube_playlists to authenticated;
grant select, insert, update, delete on table public.dim_youtube_videos to authenticated;

grant select on _dimi_rls_users to authenticated;
grant select on _dimi_rls_rows to authenticated;
grant select, insert on _dimi_rls_results to authenticated;

-- Simulate an authenticated request for User A.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', (select user_a::text from _dimi_rls_users),
    'role', 'authenticated'
  )::text,
  true
);

select pg_temp.record_result(
  'User A auth.uid() is correct',
  auth.uid() = (select user_a from _dimi_rls_users)
);

do $$
declare
  r record;
  own_count integer;
  other_count integer;
  affected integer;
begin
  for r in
    select *
    from (
      select 'dim_accounts'::text as table_name, account_a as own_id, account_b as other_id from _dimi_rls_rows
      union all
      select 'dim_profile_data', profile_a, profile_b from _dimi_rls_rows
      union all
      select 'dim_tasks', task_a, task_b from _dimi_rls_rows
      union all
      select 'dim_reminders', reminder_a, reminder_b from _dimi_rls_rows
      union all
      select 'dim_notes', note_a, note_b from _dimi_rls_rows
      union all
      select 'dim_money_transactions', transaction_a, transaction_b from _dimi_rls_rows
      union all
      select 'dim_merchant_category_rules', rule_a, rule_b from _dimi_rls_rows
      union all
      select 'dim_youtube_playlists', playlist_a, playlist_b from _dimi_rls_rows
      union all
      select 'dim_youtube_videos', video_a, video_b from _dimi_rls_rows
    ) as x
  loop
    execute format(
      'select count(*) from public.%I where id = $1',
      r.table_name
    ) into own_count using r.own_id;

    execute format(
      'select count(*) from public.%I where id = $1',
      r.table_name
    ) into other_count using r.other_id;

    perform pg_temp.record_result(
      'User A can SELECT own ' || r.table_name,
      own_count = 1
    );

    perform pg_temp.record_result(
      'User A cannot SELECT User B ' || r.table_name,
      other_count = 0
    );

    execute format(
      'update public.%I set updated_at = now() where id = $1',
      r.table_name
    ) using r.other_id;

    get diagnostics affected = row_count;

    perform pg_temp.record_result(
      'User A cannot UPDATE User B ' || r.table_name,
      affected = 0
    );

    execute format(
      'delete from public.%I where id = $1',
      r.table_name
    ) using r.other_id;

    get diagnostics affected = row_count;

    perform pg_temp.record_result(
      'User A cannot DELETE User B ' || r.table_name,
      affected = 0
    );
  end loop;
end $$;

-- User A attempts to insert rows owned by User B.
do $$
begin
  begin
    insert into public.dim_accounts (id, user_id, display_name)
    select gen_random_uuid(), user_b, 'Invalid A-to-B account'
    from _dimi_rls_users;
    perform pg_temp.record_result('User A cannot INSERT User B account', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User A cannot INSERT User B account', true);
  end;

  begin
    insert into public.dim_notes (id, user_id, title, content, category)
    select gen_random_uuid(), user_b, 'Invalid', 'Invalid', 'Test'
    from _dimi_rls_users;
    perform pg_temp.record_result('User A cannot INSERT User B note', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User A cannot INSERT User B note', true);
  end;

  begin
    insert into public.dim_money_transactions
      (id, user_id, type, amount_minor, category, occurred_on)
    select gen_random_uuid(), user_b, 'lent', 1, 'Test', now()
    from _dimi_rls_users;
    perform pg_temp.record_result('User A cannot INSERT User B transaction', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User A cannot INSERT User B transaction', true);
  end;

  begin
    insert into public.dim_youtube_playlists
      (id, user_id, youtube_playlist_id, title)
    select gen_random_uuid(), user_b, 'invalid-a-to-b', 'Invalid'
    from _dimi_rls_users;
    perform pg_temp.record_result('User A cannot INSERT User B playlist', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User A cannot INSERT User B playlist', true);
  end;
end $$;

-- Simulate an authenticated request for User B.
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', (select user_b::text from _dimi_rls_users),
    'role', 'authenticated'
  )::text,
  true
);

select pg_temp.record_result(
  'User B auth.uid() is correct',
  auth.uid() = (select user_b from _dimi_rls_users)
);

do $$
declare
  r record;
  own_count integer;
  other_count integer;
  affected integer;
begin
  for r in
    select *
    from (
      select 'dim_accounts'::text as table_name, account_b as own_id, account_a as other_id from _dimi_rls_rows
      union all
      select 'dim_profile_data', profile_b, profile_a from _dimi_rls_rows
      union all
      select 'dim_tasks', task_b, task_a from _dimi_rls_rows
      union all
      select 'dim_reminders', reminder_b, reminder_a from _dimi_rls_rows
      union all
      select 'dim_notes', note_b, note_a from _dimi_rls_rows
      union all
      select 'dim_money_transactions', transaction_b, transaction_a from _dimi_rls_rows
      union all
      select 'dim_merchant_category_rules', rule_b, rule_a from _dimi_rls_rows
      union all
      select 'dim_youtube_playlists', playlist_b, playlist_a from _dimi_rls_rows
      union all
      select 'dim_youtube_videos', video_b, video_a from _dimi_rls_rows
    ) as x
  loop
    execute format(
      'select count(*) from public.%I where id = $1',
      r.table_name
    ) into own_count using r.own_id;

    execute format(
      'select count(*) from public.%I where id = $1',
      r.table_name
    ) into other_count using r.other_id;

    perform pg_temp.record_result(
      'User B can SELECT own ' || r.table_name,
      own_count = 1
    );

    perform pg_temp.record_result(
      'User B cannot SELECT User A ' || r.table_name,
      other_count = 0
    );

    execute format(
      'update public.%I set updated_at = now() where id = $1',
      r.table_name
    ) using r.other_id;

    get diagnostics affected = row_count;

    perform pg_temp.record_result(
      'User B cannot UPDATE User A ' || r.table_name,
      affected = 0
    );

    execute format(
      'delete from public.%I where id = $1',
      r.table_name
    ) using r.other_id;

    get diagnostics affected = row_count;

    perform pg_temp.record_result(
      'User B cannot DELETE User A ' || r.table_name,
      affected = 0
    );
  end loop;
end $$;

-- User B attempts to insert rows owned by User A.
do $$
begin
  begin
    insert into public.dim_accounts (id, user_id, display_name)
    select gen_random_uuid(), user_a, 'Invalid B-to-A account'
    from _dimi_rls_users;
    perform pg_temp.record_result('User B cannot INSERT User A account', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User B cannot INSERT User A account', true);
  end;

  begin
    insert into public.dim_notes (id, user_id, title, content, category)
    select gen_random_uuid(), user_a, 'Invalid', 'Invalid', 'Test'
    from _dimi_rls_users;
    perform pg_temp.record_result('User B cannot INSERT User A note', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User B cannot INSERT User A note', true);
  end;

  begin
    insert into public.dim_money_transactions
      (id, user_id, type, amount_minor, category, occurred_on)
    select gen_random_uuid(), user_a, 'borrowed', 1, 'Test', now()
    from _dimi_rls_users;
    perform pg_temp.record_result('User B cannot INSERT User A transaction', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User B cannot INSERT User A transaction', true);
  end;

  begin
    insert into public.dim_youtube_playlists
      (id, user_id, youtube_playlist_id, title)
    select gen_random_uuid(), user_a, 'invalid-b-to-a', 'Invalid'
    from _dimi_rls_users;
    perform pg_temp.record_result('User B cannot INSERT User A playlist', false);
  exception when insufficient_privilege then
    perform pg_temp.record_result('User B cannot INSERT User A playlist', true);
  end;
end $$;

select
  test_name,
  case when passed then 'PASS' else 'FAIL' end as result
from _dimi_rls_results
order by test_name;

select
  count(*) filter (where not passed) as failures,
  count(*) as total_tests
from _dimi_rls_results;

rollback;
