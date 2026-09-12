import 'dart:math' as math;
import 'transaction_models.dart';
import 'financial_source_gate.dart';

class AmountParser {
  static int? parseMinor(String text) {
    final match = RegExp(r'(?:₹|rs\.?|inr\s*)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(text) ?? RegExp(r'(?<![a-z])([0-9][0-9,]*\.[0-9]{1,2})(?![a-z])', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    final normalized = match.group(1)!.replaceAll(',', '');
    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1 ? 0 : int.tryParse(parts[1].padRight(2, '0'));
    return fraction == null ? null : whole * 100 + fraction;
  }
}

class TransactionNormalizer {
  static String merchantIdentity(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
  static String merchantDisplay(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

class MerchantParser {
  static String parse(String text) {
    final patterns = [RegExp(r'^([A-Za-z][A-Za-z0-9 &._-]{1,60}?)\s+paid\s+you\b', caseSensitive: false), RegExp(r'\b(?:to|at|from)\s+([A-Za-z][A-Za-z0-9 &._-]{1,60}?)(?:\s+(?:via|on|using|thru)\b|[.!;,]|$)', caseSensitive: false), RegExp(r'payment\s+successful\s+(?:at|to)\s+([A-Za-z][A-Za-z0-9 &._-]{1,60})', caseSensitive: false)];
    for (final pattern in patterns) {
      final value = pattern.firstMatch(text)?.group(1)?.trim();
      if (value != null && value.isNotEmpty && !value.contains('@')) return TransactionNormalizer.merchantDisplay(value);
    }
    final vpa = RegExp(r'\b([a-z0-9._-]{2,50}@[a-z]{2,20})\b', caseSensitive: false).firstMatch(text)?.group(1);
    return vpa ?? 'Unknown';
  }
}

class TransactionParser {
  static TransactionCandidate? parse(RawTransactionEvent event) {
    final text = [event.title, event.body, event.bigText].whereType<String>().join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    final source = FinancialSourceGate.identify(event);
    if (source == null) return null;
    final amount = AmountParser.parseMinor(text);
    if (amount == null) return null;
    final lower = text.toLowerCase();
    final request = RegExp(r'payment\s+request|collect\s+request|request\s+money').hasMatch(lower);
    final failed = RegExp(r'failed|declined|cancelled|canceled|pending|unsuccessful|reversed').hasMatch(lower);
    final refund = RegExp(r'refund|refunded|reversal').hasMatch(lower);
    final credit = RegExp(r'credited|received|money received|payment received|paid you|sent you').hasMatch(lower);
    final debit = !credit && RegExp(r'debited|paid|payment successful|payment of|spent|sent|withdrawn|upi payment').hasMatch(lower);
    if (request || failed) return null;
    final direction = credit && !debit ? TransactionDirection.credit : debit ? TransactionDirection.debit : TransactionDirection.unknown;
    final type = refund ? TransactionType.refund : credit && !debit ? TransactionType.income : debit ? TransactionType.expense : TransactionType.unknown;
    if (type == TransactionType.unknown) return null;
    final merchant = MerchantParser.parse(text);
    final referenceId = RegExp(r'\b(?:upi\s*[:#-]?\s*)(\d{8,})\b', caseSensitive: false).firstMatch(text)?.group(1);
    final accountHint = RegExp(r'\b(?:a/c|account)\s*([xX*\d]{3,})', caseSensitive: false).firstMatch(text)?.group(1);
    final balanceAfterMinor = _amountAfter(text, RegExp(r'\b(?:bal|balance)\s*(?:is|:)?\s*(?:₹|rs\.?|inr)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false));
    var confidence = 0.45;
    if (debit || credit) confidence += 0.2;
    if (merchant != 'Unknown') confidence += 0.15;
    if (source != 'UNKNOWN_PAYMENT_APP') confidence += 0.1;
    if (RegExp(r'success|successful|completed|paid').hasMatch(lower)) confidence += 0.1;
    if (referenceId != null) confidence += 0.08;
    return TransactionCandidate(id: '${event.id}:$amount', amountMinor: amount, merchantName: merchant, merchantIdentity: TransactionNormalizer.merchantIdentity(merchant), direction: direction, type: type, source: source, sourcePackage: event.sourcePackage, timestamp: event.timestamp, referenceId: referenceId, accountHint: accountHint, paymentMethod: lower.contains('upi') ? 'UPI' : null, balanceAfterMinor: balanceAfterMinor, rawEventId: event.id, confidence: math.min(confidence, 0.99), status: CandidateStatus.detected, duplicateStatus: DuplicateStatus.unique, category: CategorySuggestionEngine.suggest(merchant));
  }
  static int? _amountAfter(String text, RegExp pattern) { final value = pattern.firstMatch(text)?.group(1); return value == null ? null : AmountParser.parseMinor('INR $value'); }
}

class CategorySuggestionEngine {
  static String suggest(String merchant) { final m = merchant.toLowerCase(); if (RegExp(r'swiggy|zomato|starbucks|cafe|restaurant|food').hasMatch(m)) return 'Food'; if (RegExp(r'uber|ola|metro|rapido|transport').hasMatch(m)) return 'Transport'; if (RegExp(r'netflix|spotify|hotstar').hasMatch(m)) return 'Subscriptions'; if (RegExp(r'amazon|flipkart|shopping').hasMatch(m)) return 'Shopping'; if (RegExp(r'hospital|pharmacy|doctor').hasMatch(m)) return 'Health'; if (merchant != 'Unknown' && merchant.isNotEmpty) return 'Personal'; return 'Other'; }
}

class TransactionDeduplicationEngine {
  const TransactionDeduplicationEngine({this.window = const Duration(minutes: 10)});
  final Duration window;
  DuplicateStatus compare(TransactionCandidate a, TransactionCandidate b) {
    if (a.referenceId != null && a.referenceId == b.referenceId) return DuplicateStatus.confirmed;
    final close = (a.timestamp.difference(b.timestamp)).abs() <= window;
    if (a.amountMinor == b.amountMinor && a.direction == b.direction && a.merchantIdentity == b.merchantIdentity && close) return DuplicateStatus.likely;
    if (a.amountMinor == b.amountMinor && a.merchantIdentity == b.merchantIdentity && a.timestamp.year == b.timestamp.year && a.timestamp.month == b.timestamp.month && a.timestamp.day == b.timestamp.day && close) return DuplicateStatus.possible;
    return DuplicateStatus.unique;
  }
}
