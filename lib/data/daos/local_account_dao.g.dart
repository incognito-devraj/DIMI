// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_account_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalAccountDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  LocalAccountDaoManager get managers => LocalAccountDaoManager(this);
}

class LocalAccountDaoManager {
  final _$LocalAccountDaoMixin _db;
  LocalAccountDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
}
