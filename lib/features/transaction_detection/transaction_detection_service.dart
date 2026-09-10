import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../../data/database.dart';
import 'transaction_models.dart';
import 'transaction_parser.dart';

class TransactionDetectionService {
  TransactionDetectionService(this.db);
  static const _channel = MethodChannel('com.dimi.dimi_app/transaction_detection');
  final AppDatabase db;

  Future<bool> isNotificationAccessEnabled() async => await _channel.invokeMethod<bool>('isNotificationAccessEnabled') ?? false;
  Future<void> openNotificationAccessSettings() => _channel.invokeMethod<void>('openNotificationAccessSettings');
  Future<String> detectionMode() async => await _channel.invokeMethod<String>('getDetectionMode') ?? 'Detect & Ask';
  Future<void> setDetectionMode(String mode) => _channel.invokeMethod<void>('setDetectionMode', {'mode': mode});

  Future<void> autoAddPendingHighConfidence() async {
    for (final candidate in await db.transactionDetectionDao.getPendingCandidates()) {
      if (candidate.confidenceScore < 0.8) continue;
      final isIncome = candidate.transactionType == 'INCOME';
      await db.moneyDao.insertTransaction(MoneyTransactionsCompanion.insert(type: isIncome ? 'income' : 'expense', amount: candidate.amountMinor / 100, category: candidate.category, note: Value('${candidate.merchantName} · Detected automatically'), date: candidate.occurredAt));
      await db.transactionDetectionDao.updateStatus(candidate.candidateId, 'AUTO_ADDED');
    }
  }

  Future<int> syncPendingEvents() async {
    final mode = await detectionMode();
    final items = await _channel.invokeMethod<List<dynamic>>('getPendingTransactionEvents') ?? const [];
    var imported = 0;
    for (final item in items) {
      final map = Map<String, dynamic>.from(item as Map);
      final event = RawTransactionEvent(id: map['id'] as String, sourcePackage: map['sourcePackage'] as String? ?? '', sourceType: map['sourceType'] as String? ?? 'NOTIFICATION', title: map['title'] as String?, body: map['body'] as String?, bigText: map['bigText'] as String?, timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch), receivedAt: DateTime.fromMillisecondsSinceEpoch((map['receivedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch));
      await db.transactionDetectionDao.insertEvent(TransactionDetectionEventsCompanion.insert(eventKey: event.id, sourcePackage: event.sourcePackage, sourceType: event.sourceType, title: Value(event.title), body: Value(event.body), bigText: Value(event.bigText), occurredAt: event.timestamp, receivedAt: event.receivedAt));
      final candidate = TransactionParser.parse(event);
      if (candidate == null) { await _ack(event.id); continue; }
      final recent = await db.transactionDetectionDao.recentCandidates(candidate.timestamp.subtract(const Duration(minutes: 10)));
      final existing = recent.where((row) {
        final close = (row.occurredAt.difference(candidate.timestamp)).abs() <= const Duration(minutes: 10);
        final referenceMatch = candidate.referenceId != null && row.referenceId == candidate.referenceId;
        final merchantMatch = row.merchantIdentity == candidate.merchantIdentity || row.merchantIdentity == 'unknown' || candidate.merchantIdentity == 'unknown';
        return referenceMatch || (row.amountMinor == candidate.amountMinor && row.direction == candidate.direction && close && merchantMatch);
      }).toList();
      final duplicate = existing.isNotEmpty;
      if (duplicate) {
        final primary = existing.firstWhere((row) => row.status != 'DUPLICATE', orElse: () => existing.first);
        await db.transactionDetectionDao.enrichCandidate(candidateId: primary.candidateId, source: candidate.source, referenceId: candidate.referenceId, accountHint: candidate.accountHint, paymentMethod: candidate.paymentMethod, balanceAfterMinor: candidate.balanceAfterMinor);
        if (primary.status == 'PENDING_CONFIRMATION' && mode == 'Auto-add high confidence' && candidate.confidence >= 0.95) {
          final isIncome = primary.transactionType == 'INCOME';
          await db.moneyDao.insertTransaction(MoneyTransactionsCompanion.insert(type: isIncome ? 'income' : 'expense', amount: primary.amountMinor / 100, category: primary.category, note: Value('${primary.merchantName} · Detected automatically'), date: primary.occurredAt));
          await db.transactionDetectionDao.updateStatus(primary.candidateId, 'AUTO_ADDED');
        }
        await _ack(event.id);
        imported++;
        continue;
      }
      final auto = mode == 'Auto-add high confidence' && candidate.confidence >= 0.8;
      await db.transactionDetectionDao.insertCandidate(TransactionCandidatesCompanion.insert(candidateId: candidate.id, amountMinor: candidate.amountMinor, merchantName: Value(candidate.merchantName), merchantIdentity: Value(candidate.merchantIdentity), direction: candidate.direction.name.toUpperCase(), transactionType: candidate.type.name.toUpperCase(), source: candidate.source, bankConfirmationStatus: Value(candidate.source.contains('BANK') ? 'RECEIVED' : 'NOT_RECEIVED'), sourcePackage: Value(candidate.sourcePackage), occurredAt: candidate.timestamp, referenceId: Value(candidate.referenceId), accountHint: Value(candidate.accountHint), paymentMethod: Value(candidate.paymentMethod), balanceAfterMinor: Value(candidate.balanceAfterMinor), rawEventId: Value(candidate.rawEventId), confidenceScore: candidate.confidence, status: auto ? 'AUTO_ADDED' : 'PENDING_CONFIRMATION', duplicateStatus: 'UNIQUE', category: Value(candidate.category), createdAt: DateTime.now()));
      if (auto) {
        await db.moneyDao.insertTransaction(MoneyTransactionsCompanion.insert(type: candidate.type == TransactionType.income ? 'income' : 'expense', amount: candidate.amountMinor / 100, category: candidate.category, note: Value('${candidate.merchantName} · Detected automatically'), date: candidate.timestamp));
      }
      await _ack(event.id);
      imported++;
    }
    return imported;
  }

  Future<void> _ack(String id) => _channel.invokeMethod<void>('acknowledgeTransactionEvent', {'id': id});
}
