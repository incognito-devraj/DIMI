// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_dao.dart';

// ignore_for_file: type=lint
mixin _$MoneyDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  $MoneyTransactionsTable get moneyTransactions =>
      attachedDatabase.moneyTransactions;
  MoneyDaoManager get managers => MoneyDaoManager(this);
}

class MoneyDaoManager {
  final _$MoneyDaoMixin _db;
  MoneyDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
  $$MoneyTransactionsTableTableManager get moneyTransactions =>
      $$MoneyTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.moneyTransactions,
      );
}
