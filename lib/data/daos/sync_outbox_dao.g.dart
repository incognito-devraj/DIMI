// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  SyncOutboxDaoManager get managers => SyncOutboxDaoManager(this);
}

class SyncOutboxDaoManager {
  final _$SyncOutboxDaoMixin _db;
  SyncOutboxDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}
