enum TransactionDirection { debit, credit, transfer, unknown }
enum TransactionType { expense, income, transfer, refund, paymentRequest, unknown }
enum CandidateStatus { detected, pendingConfirmation, confirmed, autoAdded, ignored, duplicate, failed }
enum DuplicateStatus { unique, confirmed, likely, possible }

class RawTransactionEvent {
  const RawTransactionEvent({required this.id, required this.sourcePackage, required this.sourceType, this.title, this.body, this.bigText, required this.timestamp, required this.receivedAt});
  final String id, sourcePackage, sourceType;
  final String? title, body, bigText;
  final DateTime timestamp, receivedAt;
}

class TransactionCandidate {
  const TransactionCandidate({required this.id, required this.amountMinor, required this.merchantName, required this.merchantIdentity, required this.direction, required this.type, required this.source, this.sourcePackage, required this.timestamp, this.referenceId, this.accountHint, this.paymentMethod, this.balanceAfterMinor, this.rawEventId, required this.confidence, required this.status, required this.duplicateStatus, required this.category});
  final String id;
  final int amountMinor;
  final String merchantName, merchantIdentity, source, category;
  final TransactionDirection direction;
  final TransactionType type;
  final String? sourcePackage, referenceId, accountHint, paymentMethod, rawEventId;
  final int? balanceAfterMinor;
  final DateTime timestamp;
  final double confidence;
  final CandidateStatus status;
  final DuplicateStatus duplicateStatus;
}
