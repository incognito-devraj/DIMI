# Sync Prerequisite Implementation Report

## Result

The local mutation metadata blocker described in this report is resolved.
The project remains intentionally pre-worker: no sync worker or remote data
mutation has been added.

The outbox exposes the required base-version and local-mutation-version
inputs, and all audited DAO update/tombstone paths now capture the
pre-mutation `updated_at` before writing and pass it to the outbox. No sync
worker or remote data mutation was added.

## Files changed

- `lib/data/tables/sync_outbox.dart`
- `lib/data/daos/sync_outbox_dao.dart`
- `test/sync_prerequisite_metadata_test.dart`
- `docs/SYNC_PREREQUISITE_IMPLEMENTATION_REPORT.md`

No Drift schema migration was added. The existing outbox `updated_at` is used
as the queued local mutation/version timestamp; `queued_at` remains queue
chronology and retry scheduling uses `next_attempt_at`.

## Metadata strategy

Each pending operation carries or derives:

- local account and authenticated identity;
- entity and local row ID;
- stable `server_id`;
- operation and retry state;
- `base_remote_updated_at`, supplied before the mutation when available;
- the local mutation timestamp through outbox `updated_at`.

For coalesced operations:

- the earliest base remote version is retained;
- the latest local mutation timestamp is retained;
- create remains create until delete supersedes it;
- delete supersedes update/create while retaining the same identity.

Retry/completion bookkeeping no longer overwrites the local mutation timestamp.

## Mutation paths audited

Audited the current mutation paths for:

- local accounts and profile data;
- tasks and reminders;
- notes;
- money transactions;
- merchant category rules;
- YouTube playlists and videos.

All paths already write local `updated_at`, preserve `server_id`, retain
`deleted_at` tombstones, and enqueue an outbox operation. The remaining issue
is that several first update/delete paths enqueue only after the write and do
not pass the pre-write acknowledged version into `base_remote_updated_at`.
Once an outbox item already exists, the DAO preserves its original base during
coalescing. A pending create correctly retains a null remote base.

## Outbox changes

`SyncOutboxDao.enqueue` now accepts:

```dart
baseRemoteUpdatedAt: previousAcknowledgedServerVersion,
localMutationAt: row.updatedAt,
```

Both are optional for backward compatibility with existing call sites, but
the future mutation boundary must provide them explicitly. New entries still
receive a UTC local timestamp when a caller omits it.

## Supabase conditional-update capability

Static inspection of the installed Supabase/PostgREST Dart client confirms
that the client API can express the required request shape:

```dart
final result = await client
    .from(table)
    .update(payload)
    .eq('id', serverId)
    .eq('updated_at', baseRemoteUpdatedAt.toIso8601String())
    .select()
    .maybeSingle();
```

The PostgREST filters and `select()` transformation are available in the
installed dependency. A returned null row/zero-row update must be treated as
a compare-and-swap conflict.

However, the application currently has no generic table update path, no
conditional-update integration test, and no live-safe test double around the
Supabase client. Therefore this is an API capability verification, not a
runtime or production verification. The existing app only uses Supabase Auth
and the YouTube Edge Function.

If the deployed REST endpoint does not return the trigger-generated row for
this request, the minimum required mechanism is an authenticated Supabase RPC
or Edge Function that performs the conditional update server-side and returns
the complete row. It must be designed before worker implementation; it was
not created here.

## Tests and results

Added `test/sync_prerequisite_metadata_test.dart` covering:

1. create with null remote base and local mutation timestamp;
2. update retaining the first remote base across a second update;
3. tombstone retaining the original base;
4. expected server ID/version metadata;
5. account-scoped outbox isolation.

`dart format` was run on the new/changed Dart files. Focused Flutter tests,
Dart analysis, and `build_runner` were attempted but produced no output and
hung in this environment. They were not repeatedly retried. Generated Drift
files were intentionally not changed because no schema change was made and
the generator did not complete.

## Final status

The pre-mutation remote-base blocker is resolved for the audited local DAO
mutation paths. The conditional REST request still requires a non-production
transport verification before remote synchronization is implemented.

After that mutation-boundary work, the conditional REST request must be
verified against a non-production Supabase test project or mocked PostgREST
transport. RLS policies and the Phase 1 schema remain unchanged.
