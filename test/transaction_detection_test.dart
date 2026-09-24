import 'package:flutter_test/flutter_test.dart';
import 'package:dimi_app/features/transaction_detection/transaction_models.dart';
import 'package:dimi_app/features/transaction_detection/transaction_parser.dart';

RawTransactionEvent event(String text, {String packageName = 'com.google.android.apps.walletnfcrel', int minute = 0}) => RawTransactionEvent(id: '$text$minute', sourcePackage: packageName, sourceType: 'NOTIFICATION', body: text, timestamp: DateTime(2026, 1, 1, 10, minute), receivedAt: DateTime(2026, 1, 1, 10, minute));

void main() {
  test('parses debit, income, requests, failures, refunds and amounts', () {
    expect(TransactionParser.parse(event('Paid ₹350 to Starbucks'))!.amountMinor, 35000);
    expect(TransactionParser.parse(event('₹500 debited from account'))!.type, TransactionType.expense);
    expect(TransactionParser.parse(event('₹2,000 credited'))!.type, TransactionType.income);
    expect(TransactionParser.parse(event('₹500 payment request')), isNull);
    expect(TransactionParser.parse(event('₹500 payment failed')), isNull);
    expect(TransactionParser.parse(event('₹500 refunded'))!.type, TransactionType.refund);
  });

  test('supports the real rupee sign and treats refunds as credits', () {
    final incoming = TransactionParser.parse(event('\u20B9500 credited'))!;
    expect(incoming.amountMinor, 50000);
    expect(incoming.direction, TransactionDirection.credit);
    final refund = TransactionParser.parse(event('\u20B9500 refunded'))!;
    expect(refund.direction, TransactionDirection.credit);
  });

  test('does not guess when a notification contains both directions', () {
    expect(TransactionParser.parse(event('INR 500 debited and INR 500 credited')), isNull);
  });

  test('normalizes merchants and identifies sources', () {
    final candidate = TransactionParser.parse(event('Paid Rs. 1,250.50 at STARBUCKS'))!;
    expect(candidate.amountMinor, 125050);
    expect(candidate.merchantIdentity, 'starbucks');
    expect(candidate.source, 'GOOGLE_PAY_NOTIFICATION');
  });

  test('classifies incoming Google Pay and extracts bank fields', () {
    final incoming = TransactionParser.parse(event('RAHUL MUKHERJEE paid you ₹1.00'))!;
    expect(incoming.direction, TransactionDirection.credit);
    expect(incoming.type, TransactionType.income);
    expect(incoming.source, 'GOOGLE_PAY_NOTIFICATION');
    final bank = TransactionParser.parse(event('A/c X2213 debited INR 1.00 Dt 10-09-26 12:43:00 to RAHUL MUKHERJEE thru UPI:129352412041 Bal INR 192.16', packageName: 'com.google.android.apps.messaging'))!;
    expect(bank.direction, TransactionDirection.debit);
    expect(bank.type, TransactionType.expense);
    expect(bank.referenceId, '129352412041');
    expect(bank.accountHint, 'X2213');
    expect(bank.paymentMethod, 'UPI');
    expect(bank.balanceAfterMinor, 19216);
  });

  test('deduplicates close cross-source transactions but keeps distant ones unique', () {
    final a = TransactionParser.parse(event('Paid ₹500 to Starbucks', minute: 0))!;
    final b = TransactionParser.parse(event('A/c X2213 debited INR 500.00 to Starbucks thru UPI:123456789 Bal INR 1000.00', packageName: 'com.google.android.apps.messaging', minute: 1))!;
    final c = TransactionParser.parse(event('Paid ₹500 to Starbucks', minute: 30))!;
    final engine = const TransactionDeduplicationEngine();
    expect(engine.compare(a, b), isNot(DuplicateStatus.unique));
    expect(engine.compare(a, c), DuplicateStatus.unique);
  });

  test('rejects financial-looking WhatsApp and unknown notifications before parsing', () {
    for (final text in ['paid ₹1000', 'received ₹1000', 'debited ₹15', 'credited ₹500', '₹100', 'paid received ₹1']) {
      expect(TransactionParser.parse(event(text, packageName: 'com.whatsapp')), isNull);
      expect(TransactionParser.parse(event(text, packageName: 'com.example.random')), isNull);
    }
    expect(TransactionParser.parse(event('Open Google Pay ₹100')), isNull);
    expect(TransactionParser.parse(event('Paid ₹1 to Rahul', packageName: 'com.google.android.apps.nbu.paisa.user'))!.type, TransactionType.expense);
    expect(TransactionParser.parse(event('Payment successful. You paid ₹100 to SWIGGY'))!.type, TransactionType.expense);
  });
}
