# DIMI Supabase Phase 1 Implementation

Status: repository implementation complete; remote deployment pending project access.

This phase adds the approved Supabase schema and ownership boundary without adding
the synchronization worker. SQLite remains the immediate local source of truth,
and the existing UI/services continue to operate without a network connection.

## Tables created by the migration

`supabase/migrations/20260919000100_dimi_phase1_schema_rls.sql` creates:

- `dim_accounts`
- `dim_profile_data`
- `dim_tasks`
- `dim_reminders`
- `dim_notes`
- `dim_money_transactions`
- `dim_merchant_category_rules`
- `dim_youtube_playlists`
- `dim_youtube_videos`

Every cloud row has a UUID `id`, authenticated `user_id`, `created_at`,
`updated_at`, and nullable `deleted_at`. The local additive migration keeps local
integer primary keys and adds nullable `server_id`, `updated_at` where missing,
and `deleted_at` to syncable local tables. `server_id` is the only future mapping
between a local row and its Supabase row.

No Loans table, repayment lifecycle, detection-event table, detection-candidate
table, outbox, or sync worker is created. Finance accepts only `expense`,
`income`, `lent`, and `borrowed`; `amount_minor` remains an integer. Detection
events/candidates, notification IDs, notification schedules, and derived heatmap
data remain local-only.

## Relationships and ownership

- `dim_accounts.user_id` references `auth.users.id` and is unique.
- `dim_profile_data.user_id` references the account row for the same auth user.
- Every other table has a direct `user_id` foreign key to `auth.users.id`.
- Reminders use `(task_id, user_id)` so a reminder cannot link across users.
- Videos use `(playlist_id, user_id)` so a video cannot link across users.
- Local `auth_user_id` maps to Supabase `auth.users.id`; local account
  `server_id` maps to `dim_accounts.id`.
- Offline accounts remain local and are never silently merged with Google data.

## RLS and indexes

RLS is enabled and forced on every `dim_*` table. For each table the migration
creates authenticated-user-only SELECT, INSERT, UPDATE, and DELETE policies.
Every policy requires `user_id = auth.uid()`; UPDATE also checks the new row.
Ownership and `(user_id, updated_at)`, deletion, relationship, and playlist
ordering indexes are included for future sync queries.

The migration is idempotent for the objects it owns, but it has not been applied
to a remote project in this repository because no Supabase project reference,
CLI configuration, or database connection is present. Therefore remote RLS
execution and two-user isolation tests are still required after project access
is supplied. The SQL must be applied through the normal reviewed migration path,
not by manually editing production tables.

## Verification performed

- Local Drift schema tests verify the additive metadata, legacy-table absence,
  local foreign keys, finance types, and offline account isolation.
- SQL review verifies all nine cloud tables have RLS, four ownership policies,
  user/sync indexes, UUID identity, and no Loans table.
- Remote User A/User B SELECT/INSERT/UPDATE/DELETE tests: not run because no
  configured Supabase project is available.
- Flutter analyze/test/debug build: run after Drift code generation; results are
  recorded in the handoff response.

## Phase boundary

This phase does not implement push/pull synchronization, conflict resolution,
tombstone processing, account migration, or notification rebuilding. Those
belong to the later sync-engine phase.
