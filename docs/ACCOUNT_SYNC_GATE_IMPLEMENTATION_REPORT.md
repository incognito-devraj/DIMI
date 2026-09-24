# Account Sync Gate Implementation Report

## Lifecycle audited

Audited startup, restored Supabase sessions, Google OAuth completion through
auth-state events, authenticated local-account creation/upsert, local account
activation, logout, and supported local account switching.

The previous risks were an account-1 fallback, unawaited auth transitions,
startup work running before authenticated-account activation, and logout
clearing the account context only after sign-out handling had already begun.

## Files changed

- `lib/services/auth_service.dart`
- `lib/main.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/data/database.dart`
- `test/local_database_v9_test.dart`

No outbox schema, Supabase schema, RLS policy, or sync worker was changed.

## Ordering guarantees established

- `AppDatabase` now starts with active account ID `0`, meaning no account
  context, instead of silently assuming local account 1.
- Startup checks the restored Supabase user first. If present, it awaits
  authenticated local-account resolution, profile upsert, and activation
  before transaction-detection processing or reminder scheduling. Without a
  session, it explicitly activates the offline account first.
- Auth transitions are serialized through `AuthService` so login, restoration,
  account switching, and logout cannot overlap activation work.
- Authenticated identity is matched by Supabase `user.id` to
  `local_accounts.auth_user_id`; no authenticated path chooses an account by
  integer ID.
- Logout waits for the current account transition, invalidates the context,
  activates the offline account, and only then calls Supabase sign-out.
- Future sync code can call `awaitAuthenticatedContext()` to obtain a verified
  local-account/Supabase-user pair and a generation token. It can use
  `isContextCurrent()` before applying any result.
- Existing outbox entries remain keyed by their local account. Account
  switching therefore changes the active context without moving or mixing
  pending work.

## Tests added/updated

`test/local_database_v9_test.dart` now covers:

- authenticated account activation before scoped task work;
- separate pending outbox ownership for two authenticated local accounts;
- switching back to the first account without exposing the second account's
  task;
- returning to the offline account after authenticated use;
- existing authenticated-account separation and outbox relationship tests.

The test suite was not rerun through Flutter because the known Flutter command
hangs without output in this environment. It was not repeatedly retried.

## Analysis results

- Narrow Dart analysis of the changed lifecycle files and tests: passed with
  no errors.
- Full Dart analysis: no errors; existing warnings/infos remain.
- Flutter focused tests: not completed because of the known Flutter tooling
  hang.

## Remaining blocker

The account activation/synchronization gate is implemented. The Flutter test
runner environment still needs to be repaired before runtime test results can
be confirmed. The sync worker, remote push/pull, cursors, and conflict
resolution remain intentionally unimplemented.
