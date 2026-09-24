import 'package:drift/drift.dart';
import '../database.dart';
import 'sync_outbox_dao.dart';
import '../tables/transaction_detection.dart';

part 'transaction_detection_dao.g.dart';

@DriftAccessor(tables: [TransactionDetectionEvents, TransactionCandidates, MerchantCategoryRules])
class TransactionDetectionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDetectionDaoMixin {
  TransactionDetectionDao(super.db);

  Future<int> insertEvent(TransactionDetectionEventsCompanion event) => into(transactionDetectionEvents).insert(event.copyWith(localAccountId: Value(db.activeAccountId)), mode: InsertMode.insertOrIgnore);
  Future<int> insertCandidate(TransactionCandidatesCompanion candidate) => into(transactionCandidates).insert(candidate.copyWith(localAccountId: Value(db.activeAccountId)), mode: InsertMode.insertOrIgnore);
  Future<TransactionCandidate?> findCandidate(String id) => (select(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.candidateId.equals(id))).getSingleOrNull();
  Future<List<TransactionCandidate>> recentCandidates(DateTime since) => (select(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.occurredAt.isBiggerOrEqualValue(since))).get();
  Stream<List<TransactionCandidate>> watchPending() => (select(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.status.isIn(['DETECTED', 'PENDING_CONFIRMATION']))..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).watch();
  Future<List<TransactionCandidate>> getPendingCandidates() => (select(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.status.equals('PENDING_CONFIRMATION'))).get();
  Future<int> deleteExpired(DateTime now) async {
    final candidates = await (delete(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.expiresAt.isSmallerThanValue(now))).go();
    final events = await (delete(transactionDetectionEvents)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.expiresAt.isSmallerThanValue(now))).go();
    return candidates + events;
  }
  Future<void> enrichCandidate({required String candidateId, required String source, String? referenceId, String? accountHint, String? paymentMethod, int? balanceAfterMinor}) async {
    final current = await (select(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.candidateId.equals(candidateId))).getSingleOrNull();
    if (current == null) return;
    final sources = current.source.split('+').toSet()..add(source);
    await (update(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.candidateId.equals(candidateId))).write(TransactionCandidatesCompanion(
      source: Value(sources.join('+')),
      bankConfirmationStatus: Value(sources.any((item) => item.contains('BANK')) ? 'RECEIVED' : current.bankConfirmationStatus),
      referenceId: referenceId == null ? const Value.absent() : Value(referenceId),
      accountHint: accountHint == null ? const Value.absent() : Value(accountHint),
      paymentMethod: paymentMethod == null ? const Value.absent() : Value(paymentMethod),
      balanceAfterMinor: balanceAfterMinor == null ? const Value.absent() : Value(balanceAfterMinor),
    ));
  }
  Future<void> updateStatus(String id, String status) => (update(transactionCandidates)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.candidateId.equals(id))).write(TransactionCandidatesCompanion(status: Value(status), updatedAt: Value(DateTime.now())));
  Future<void> saveCategory(String merchant, String category) async {
    final existing = await (select(merchantCategoryRules)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.merchantIdentity.equals(merchant))).getSingleOrNull();
    await into(merchantCategoryRules).insertOnConflictUpdate(MerchantCategoryRulesCompanion.insert(localAccountId: Value(db.activeAccountId), merchantIdentity: merchant, category: category, createdAt: Value(DateTime.now()), updatedAt: Value(DateTime.now()), deletedAt: const Value(null)));
    final row = await (select(merchantCategoryRules)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.merchantIdentity.equals(merchant))).getSingle();
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.merchantRule, localRowId: row.id, operation: existing == null ? OutboxOperation.create : OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: existing?.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.merchantRule);
  }
  Future<String?> preferredCategory(String merchant) async => (select(merchantCategoryRules)..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.merchantIdentity.equals(merchant))).getSingleOrNull().then((row) => row?.category);
}
