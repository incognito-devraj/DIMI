import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/transaction_detection.dart';

part 'transaction_detection_dao.g.dart';

@DriftAccessor(tables: [TransactionDetectionEvents, TransactionCandidates, MerchantCategoryRules])
class TransactionDetectionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDetectionDaoMixin {
  TransactionDetectionDao(super.db);

  Future<int> insertEvent(TransactionDetectionEventsCompanion event) => into(transactionDetectionEvents).insert(event, mode: InsertMode.insertOrIgnore);
  Future<int> insertCandidate(TransactionCandidatesCompanion candidate) => into(transactionCandidates).insert(candidate, mode: InsertMode.insertOrIgnore);
  Future<TransactionCandidate?> findCandidate(String id) => (select(transactionCandidates)..where((t) => t.candidateId.equals(id))).getSingleOrNull();
  Future<List<TransactionCandidate>> recentCandidates(DateTime since) => (select(transactionCandidates)..where((t) => t.occurredAt.isBiggerOrEqualValue(since))).get();
  Stream<List<TransactionCandidate>> watchPending() => (select(transactionCandidates)..where((t) => t.status.isIn(['DETECTED', 'PENDING_CONFIRMATION']))..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])).watch();
  Future<List<TransactionCandidate>> getPendingCandidates() => (select(transactionCandidates)..where((t) => t.status.equals('PENDING_CONFIRMATION'))).get();
  Future<void> enrichCandidate({required String candidateId, required String source, String? referenceId, String? accountHint, String? paymentMethod, int? balanceAfterMinor}) async {
    final current = await (select(transactionCandidates)..where((t) => t.candidateId.equals(candidateId))).getSingleOrNull();
    if (current == null) return;
    final sources = current.source.split('+').toSet()..add(source);
    await (update(transactionCandidates)..where((t) => t.candidateId.equals(candidateId))).write(TransactionCandidatesCompanion(
      source: Value(sources.join('+')),
      bankConfirmationStatus: Value(sources.any((item) => item.contains('BANK')) ? 'RECEIVED' : current.bankConfirmationStatus),
      referenceId: referenceId == null ? const Value.absent() : Value(referenceId),
      accountHint: accountHint == null ? const Value.absent() : Value(accountHint),
      paymentMethod: paymentMethod == null ? const Value.absent() : Value(paymentMethod),
      balanceAfterMinor: balanceAfterMinor == null ? const Value.absent() : Value(balanceAfterMinor),
    ));
  }
  Future<void> updateStatus(String id, String status) => (update(transactionCandidates)..where((t) => t.candidateId.equals(id))).write(TransactionCandidatesCompanion(status: Value(status)));
  Future<void> saveCategory(String merchant, String category) => into(merchantCategoryRules).insertOnConflictUpdate(MerchantCategoryRulesCompanion.insert(merchantIdentity: merchant, category: category, updatedAt: DateTime.now()));
  Future<String?> preferredCategory(String merchant) async => (select(merchantCategoryRules)..where((t) => t.merchantIdentity.equals(merchant))).getSingleOrNull().then((row) => row?.category);
}
