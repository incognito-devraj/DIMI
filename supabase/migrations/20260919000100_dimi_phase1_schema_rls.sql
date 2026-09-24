-- DIMI Phase 1: cloud schema, ownership, sync metadata, and RLS.
-- This migration intentionally does not create a sync worker, an outbox, or
-- any detection tables. It also does not create a loans table.

create extension if not exists pgcrypto;

create table if not exists public.dim_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  last_login_at timestamptz,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.dim_profile_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.dim_accounts(user_id) on delete cascade,
  role text not null default '',
  phone text not null default '',
  college text not null default '',
  semester text not null default '',
  points integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.dim_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  category text not null,
  is_planner_entry boolean not null default false,
  local_date date not null,
  due_time_hhmm text,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (id, user_id)
);

create table if not exists public.dim_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_id uuid,
  title text not null,
  due_at timestamptz not null,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (id, user_id),
  foreign key (task_id, user_id)
    references public.dim_tasks(id, user_id) on delete set null (task_id)
);

create table if not exists public.dim_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  category text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (id, user_id)
);

create table if not exists public.dim_money_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('expense', 'income', 'lent', 'borrowed')),
  amount_minor bigint not null,
  currency char(3) not null default 'INR',
  category text not null,
  note text,
  counterparty text,
  occurred_on timestamptz not null,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (id, user_id)
);

create table if not exists public.dim_merchant_category_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  merchant_identity text not null,
  category text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, merchant_identity),
  unique (id, user_id)
);

create table if not exists public.dim_youtube_playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  youtube_playlist_id text not null,
  title text not null,
  description text not null default '',
  channel_title text not null default '',
  thumbnail_url text not null default '',
  total_videos integer not null default 0,
  total_duration_seconds integer not null default 0,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, youtube_playlist_id),
  unique (id, user_id)
);

create table if not exists public.dim_youtube_videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  playlist_id uuid not null,
  youtube_video_id text not null,
  title text not null,
  thumbnail_url text not null default '',
  position integer not null,
  duration_seconds integer not null default 0,
  duration_iso text not null default '',
  completed boolean not null default false,
  watched_at timestamptz,
  last_position_seconds integer not null default 0,
  progress_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (playlist_id, youtube_video_id),
  unique (id, user_id),
  foreign key (playlist_id, user_id)
    references public.dim_youtube_playlists(id, user_id) on delete cascade
);

create or replace function public.dim_set_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'dim_accounts', 'dim_profile_data', 'dim_tasks', 'dim_reminders',
    'dim_notes', 'dim_money_transactions', 'dim_merchant_category_rules',
    'dim_youtube_playlists', 'dim_youtube_videos'
  ] loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_updated_at', table_name
    );
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.dim_set_updated_at()',
      table_name || '_updated_at', table_name
    );
  end loop;
end $$;

create index if not exists dim_accounts_user_updated_idx
  on public.dim_accounts(user_id, updated_at);
create index if not exists dim_profile_data_user_updated_idx
  on public.dim_profile_data(user_id, updated_at);
create index if not exists dim_tasks_user_updated_idx
  on public.dim_tasks(user_id, updated_at);
create index if not exists dim_tasks_user_deleted_idx
  on public.dim_tasks(user_id, deleted_at);
create index if not exists dim_reminders_user_updated_idx
  on public.dim_reminders(user_id, updated_at);
create index if not exists dim_reminders_user_task_idx
  on public.dim_reminders(user_id, task_id);
create index if not exists dim_notes_user_updated_idx
  on public.dim_notes(user_id, updated_at);
create index if not exists dim_money_transactions_user_updated_idx
  on public.dim_money_transactions(user_id, updated_at);
create index if not exists dim_money_transactions_user_deleted_idx
  on public.dim_money_transactions(user_id, deleted_at);
create index if not exists dim_merchant_rules_user_updated_idx
  on public.dim_merchant_category_rules(user_id, updated_at);
create index if not exists dim_playlists_user_updated_idx
  on public.dim_youtube_playlists(user_id, updated_at);
create index if not exists dim_videos_user_updated_idx
  on public.dim_youtube_videos(user_id, updated_at);
create index if not exists dim_videos_playlist_position_idx
  on public.dim_youtube_videos(playlist_id, position);

alter table public.dim_accounts enable row level security;
alter table public.dim_profile_data enable row level security;
alter table public.dim_tasks enable row level security;
alter table public.dim_reminders enable row level security;
alter table public.dim_notes enable row level security;
alter table public.dim_money_transactions enable row level security;
alter table public.dim_merchant_category_rules enable row level security;
alter table public.dim_youtube_playlists enable row level security;
alter table public.dim_youtube_videos enable row level security;

alter table public.dim_accounts force row level security;
alter table public.dim_profile_data force row level security;
alter table public.dim_tasks force row level security;
alter table public.dim_reminders force row level security;
alter table public.dim_notes force row level security;
alter table public.dim_money_transactions force row level security;
alter table public.dim_merchant_category_rules force row level security;
alter table public.dim_youtube_playlists force row level security;
alter table public.dim_youtube_videos force row level security;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'dim_accounts', 'dim_profile_data', 'dim_tasks', 'dim_reminders',
    'dim_notes', 'dim_money_transactions', 'dim_merchant_category_rules',
    'dim_youtube_playlists', 'dim_youtube_videos'
  ] loop
    execute format('drop policy if exists %I on public.%I', table_name || '_select_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_insert_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_update_own', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_delete_own', table_name);
    execute format('create policy %I on public.%I for select to authenticated using (user_id = (select auth.uid()))', table_name || '_select_own', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check (user_id = (select auth.uid()))', table_name || '_insert_own', table_name);
    execute format('create policy %I on public.%I for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', table_name || '_update_own', table_name);
    execute format('create policy %I on public.%I for delete to authenticated using (user_id = (select auth.uid()))', table_name || '_delete_own', table_name);
  end loop;
end $$;
