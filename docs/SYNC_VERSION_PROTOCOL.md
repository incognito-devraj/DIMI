# DIMI Sync Version Protocol

Status: protocol defined and implemented as a pure, testable comparison
component. This document does not implement a sync worker, Supabase push/pull,
RLS changes, or a schema migration.

## Version model

Every synced row has the existing metadata:

```text
server_id   stable UUID identity
updated_at  local provisional timestamp, or last server-acknowledged version
deleted_at  nullable tombstone timestamp
```

The durable outbox has the existing `base_remote_updated_at` field. It means
the exact Supabase `updated_at` observed immediately before the local
mutation. It is the compare-and-swap base for that mutation.

There are two kinds of timestamp:

1. A local mutation timestamp is generated in UTC before the SQLite
   transaction commits. It must be strictly greater than the previous local
   `updated_at` when the device clock is equal or behind. This preserves local
   ordering and makes offline edits observable.
2. A server version is the UTC `updated_at` returned by Supabase after an
   insert/update. The Phase 1 `now()` default and `before update` trigger
   generate it. The client must not send a local timestamp as an authoritative
   remote version and must replace local `updated_at` with the returned server
   value after acknowledgement.

The local timestamp is never used by itself to decide remote ownership. In
particular, a device clock in 2035 does not beat a server version from 2026.
The authoritative ordering is the order of accepted server mutations,
observed through the server version and the outbox base comparison.

## Authoritative source

Supabase is authoritative for the remote copy and its row version. The
existing trigger `public.dim_set_updated_at()` sets `updated_at = now()` for
every update, and the existing column default sets it on insert. The future
worker must:

- use `server_id` as identity;
- omit or ignore client authority for `updated_at` on remote writes;
- request/return the complete row after the write;
- persist that returned server `updated_at` in SQLite in the same local apply
  transaction as the acknowledgement;
- use an update filtered by `id`, authenticated ownership, and the expected
  `base_remote_updated_at` (compare-and-swap);
- treat zero updated rows as a conflict, not as success.

If the direct Supabase API cannot express the timestamp compare-and-swap
without accepting a client-controlled timestamp, the worker must stop and use
an approved server-side RPC/Edge Function. No such server object is added in
this step.

SQLite/Drift remains the immediate application source of truth. A failed
remote operation never rolls back a committed local mutation.

## Local mutation behavior

For every create, update, completion/progress change, enable/disable change,
or tombstone:

1. Read the current row, including its last acknowledged server version.
2. Save that version as `base_remote_updated_at` in the outbox entry. For a
   never-uploaded create, the base is null.
3. Generate a local timestamp with
   `max(UTC now, previous local updated_at + 1 microsecond)`.
4. Update the row's local `updated_at` (and `deleted_at` for a tombstone) and
   enqueue/coalesce the outbox mutation in one SQLite transaction.
5. Keep the same `server_id` for the life of the row. A retry never generates
   another identity.

When multiple local edits coalesce, retain the earliest base remote version and
the latest local payload. A delete supersedes earlier operations but retains
the tombstoned row and its identity.

On successful remote acknowledgement, replace local `updated_at` with the
server-returned version before completing the outbox entry. If another local
edit happened meanwhile, the worker must not overwrite that newer local row;
it leaves/rebases a new pending outbox mutation against the acknowledgement.

## Push comparison behavior

Before pushing a pending item, fetch the current remote row by `server_id` and
compare its `updated_at` to the outbox base:

| Remote version vs base | Classification | Action |
|---|---|---|
| exactly equal (including both null) | local newer | conditional push is eligible |
| different | conflict | do not overwrite by ordinary update; resolve below |

This is intentionally not `local.updated_at > remote.updated_at`. The local
timestamp may be skewed and is only a provisional ordering marker.

For an eligible push, the worker performs a conditional update/insert. The
server trigger creates the new authoritative version. A retry of the same
acknowledged operation is idempotent because it uses the same `server_id`; an
already-applied version is recognized by re-reading the row and matching the
outbox payload/version before attempting another write.

## Pull comparison behavior

The worker compares the pulled row with the local row and any pending outbox:

| Local state | Comparison | Result |
|---|---|---|
| pending mutation and remote version equals its base | local newer | keep local row; push conditionally |
| pending mutation and remote version differs from its base | conflict | apply normal/tombstone/YouTube rule |
| no pending mutation and server versions equal, payload equal | equal/same version | no-op |
| no pending mutation and server versions differ | remote newer | apply remote row |
| same timestamp but payload differs | conflict/ambiguous | remote wins for normal entities |

“Remote newer” means newer than the last server version applied locally; it does
not mean the remote timestamp is numerically greater than a device-generated
timestamp. Thus clock skew cannot make a local edit win remotely.

## Conflict resolution

### Normal entities

The exact rule is:

> If the remote row changed after the local mutation's recorded base, the
> remote server version wins. If it did not change after the base, the local
> mutation is accepted by conditional push.

This is server-authoritative last-write-wins: the first mutation accepted after
the shared base establishes the next server version. A later concurrent
mutation cannot overwrite it using a stale base. Equal timestamps with
different payloads are treated as an ambiguity/conflict and resolve remote-
wins; equal timestamp plus equal payload is an idempotent no-op.

After choosing remote, replace the local payload and `updated_at` with the
remote row, clear/supersede the pending outbox item, and retain diagnostic
outcome information where the worker supports it.

### Tombstone conflict behavior

A tombstone is a real version, not a physical deletion. A local tombstone that
finds a remote live update for the same `server_id` is delete-wins. The worker
must re-read the remote row, then write the tombstone as a new server version
using the authenticated owner; it must never turn the old identity back into a
live local row. If the remote row is already tombstoned, the operation is
idempotent and the greatest acknowledged server version is retained.

A live edit after intentional deletion is a new record with a new
`server_id`; it is not a resurrection of the tombstoned identity.

## YouTube conflict behavior

Playlist/video rows are merged by field group, never replaced wholesale:

- Refreshable metadata: title, description, channel/thumbnail, duration,
  position, total counts, and refresh timestamps.
- Durable progress: `completed`, `watched_at`, `last_position_seconds`, and
  `progress_updated_at`.

An incoming metadata-only update must preserve local progress, even if the
remote row serializes default/older progress fields. A local progress update
must preserve remote metadata. If both sides changed progress, the same
server-version compare-and-swap rule applies: the server-accepted version wins.
`progress_updated_at` is retained for product display and diagnostics, but it
is not independently authoritative because the Phase 1 schema does not
server-generate it.

If a local tombstone conflicts with a remote live playlist/video row, the
tombstone rule above wins. Parent/child identity and playlist ownership are
never changed by metadata refresh order.

## Retry and idempotency implications

- Retry with the same `server_id`, account, operation, base version, and
  payload.
- Never retry under a different authenticated local account.
- Network timeout/5xx/rate-limit/auth-refresh failures remain retryable.
- A conditional-update conflict is not a transient transport retry; classify
  and resolve it using this protocol.
- On process death, processing entries are returned to pending/retryable state
  by the future worker's lease recovery. The row remains local and visible.
- Repeated pulls are safe: equal version plus equal payload is a no-op.
- Repeated tombstone pushes are safe because the tombstone is retained and
  addressed by stable `server_id`.

## Exact algorithm / pseudocode

```text
local_mutation(row, operation):
  base = row.last_acknowledged_server_updated_at
  local_now = utc_now()
  row.updated_at = max(local_now, row.updated_at + 1 microsecond)
  if operation == delete:
    row.deleted_at = row.updated_at
  atomically save row and enqueue(row.server_id, operation, base, row.payload)

push(item):
  remote = get_by_server_id(item.server_id)
  if remote.updated_at == item.base_remote_updated_at:
    result = conditional_write(item.payload,
                               where updated_at == item.base_remote_updated_at)
    if result.accepted:
      atomically apply server result.updated_at and complete item
    else:
      return conflict
  else:
    return conflict

pull(remote):
  local = get_local(remote.server_id)
  item = pending_outbox(remote.server_id)
  if item != null:
    if remote.updated_at == item.base_remote_updated_at:
      keep local; schedule conditional push
    else if local.deleted_at != null:
      write remote tombstone as a new server version
    else if entity == youtube:
      merge metadata/progress groups; server version wins for same group
    else:
      apply remote (normal remote-wins)
  else if local.last_server_version == remote.updated_at:
    no-op if payload equal; otherwise remote-wins ambiguity
  else:
    apply remote and its server updated_at
```

## Focused test cases

Implemented in `test/sync_version_protocol_test.dart`:

1. Equal local clock values advance by one microsecond.
2. A device clock moving backwards does not move local mutation ordering
   backwards.
3. Remote equal to the outbox base classifies a pending local edit as local
   newer.
4. Remote changed after the base classifies the operation as conflict even
   when the device clock is far ahead.
5. Equal server version plus equal payload is equal; equal timestamp plus
   different/unknown payload is conflict.
6. A numerically earlier remote timestamp is still remote-newer when it is a
   different server version, proving no device-clock comparison is used.
7. Tombstone conflict is delete-wins.

## Schema assessment and unresolved questions

No Supabase schema change is required for this protocol. The existing
server-generated `updated_at`, trigger, `server_id`, `deleted_at`, and local
outbox `base_remote_updated_at` are sufficient for conditional row versions.

Before implementing the worker, the direct Supabase client path must be
verified to support the conditional update and to return the trigger-generated
row. If it cannot, stop and design an additive RPC/Edge Function; do not
silently fall back to an unconditional client timestamp update.

The existing local mutation boundary must also pass the pre-mutation
acknowledged server version into `base_remote_updated_at` for every mutation
path. This protocol component does not implement that worker or retrofit all
DAO call sites.

Tombstone retention/compaction remains an operational decision, as does the
diagnostic retention period for resolved conflicts. Neither affects the
version comparison rules.
