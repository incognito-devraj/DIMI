// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_dao.dart';

// ignore_for_file: type=lint
mixin _$MoneyDaoMixin on DatabaseAccessor<AppDatabase> {
  $MoneyTransactionsTable get moneyTransactions =>
      attachedDatabase.moneyTransactions;
  MoneyDaoManager get managers => MoneyDaoManager(this);
}

class MoneyDaoManager {
  final _$MoneyDaoMixin _db;
  MoneyDaoManager(this._db);
  $$MoneyTransactionsTableTableManager get moneyTransactions =>
      $$MoneyTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.moneyTransactions,
      );
}
