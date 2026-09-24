// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_detection_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionDetectionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  $TransactionDetectionEventsTable get transactionDetectionEvents =>
      attachedDatabase.transactionDetectionEvents;
  $TransactionCandidatesTable get transactionCandidates =>
      attachedDatabase.transactionCandidates;
  $MerchantCategoryRulesTable get merchantCategoryRules =>
      attachedDatabase.merchantCategoryRules;
  TransactionDetectionDaoManager get managers =>
      TransactionDetectionDaoManager(this);
}

class TransactionDetectionDaoManager {
  final _$TransactionDetectionDaoMixin _db;
  TransactionDetectionDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
  $$TransactionDetectionEventsTableTableManager
  get transactionDetectionEvents =>
      $$TransactionDetectionEventsTableTableManager(
        _db.attachedDatabase,
        _db.transactionDetectionEvents,
      );
  $$TransactionCandidatesTableTableManager get transactionCandidates =>
      $$TransactionCandidatesTableTableManager(
        _db.attachedDatabase,
        _db.transactionCandidates,
      );
  $$MerchantCategoryRulesTableTableManager get merchantCategoryRules =>
      $$MerchantCategoryRulesTableTableManager(
        _db.attachedDatabase,
        _db.merchantCategoryRules,
      );
}
