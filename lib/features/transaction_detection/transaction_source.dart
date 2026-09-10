import 'transaction_models.dart';

abstract interface class TransactionSourceAdapter {
  bool supports(RawTransactionEvent event);
  RawTransactionEvent? extract(RawTransactionEvent event);
}

/// Notification access is the first adapter. SMS remains deliberately an
/// interface until the distribution's policy and user-consent requirements
/// allow a compliant implementation.
abstract interface class BankSmsTransactionSource implements TransactionSourceAdapter {}

class TransactionSourceRegistry {
  static const packageHints = <String, String>{
    'com.google.android.apps.nbu.paisa.user': 'GOOGLE_PAY_NOTIFICATION',
    'com.google.android.apps.walletnfcrel': 'GOOGLE_PAY_NOTIFICATION',
    'com.phonepe.app': 'PHONEPE_NOTIFICATION',
    'net.one97.paytm': 'PAYTM_NOTIFICATION',
    'com.naviapp': 'NAVI_NOTIFICATION',
  };
  const TransactionSourceRegistry(this.adapters);
  final List<TransactionSourceAdapter> adapters;
  RawTransactionEvent? extract(RawTransactionEvent event) {
    for (final adapter in adapters) { if (adapter.supports(event)) return adapter.extract(event); }
    return event;
  }
}
