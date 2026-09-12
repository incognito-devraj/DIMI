import 'transaction_models.dart';

class BankNotificationValidator {
  static bool isValid(String text) {
    final value = text.toLowerCase();
    final hasAccount = RegExp(r'a/c|account|bank|\bx+\d{2,}', caseSensitive: false).hasMatch(value);
    final hasDirection = RegExp(r'debited|credited|withdrawn|deposited|received').hasMatch(value);
    final hasContext = RegExp(r'upi|txn|transaction|ref|utr|bal|balance|dt\b|date').hasMatch(value);
    final hasAmount = RegExp(r'₹|rs\.?|inr|\b\d+[,.]\d{1,2}\b').hasMatch(value);
    return hasAccount && hasDirection && hasContext && hasAmount && !RegExp(r'otp|verification|password|login code').hasMatch(value);
  }
}

class FinancialSourceGate {
  static const _googlePay = {'com.google.android.apps.nbu.paisa.user', 'com.google.android.apps.walletnfcrel'};
  static const _phonePe = {'com.phonepe.app'};
  static const _paytm = {'net.one97.paytm'};
  static const _navi = {'com.naviapp'};
  static const _amazon = {'com.amazon.mShop.android.shopping'};
  static const _cred = {'com.dreamplug.androidapp'};
  static const _messages = {'com.google.android.apps.messaging'};

  static String? identify(RawTransactionEvent event) {
    final packageName = event.sourcePackage.toLowerCase();
    final text = [event.title, event.body, event.bigText].whereType<String>().join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_googlePay.contains(packageName)) return _validPaymentText(text) ? 'GOOGLE_PAY_NOTIFICATION' : null;
    if (_phonePe.contains(packageName)) return _validPaymentText(text) ? 'PHONEPE_NOTIFICATION' : null;
    if (_paytm.contains(packageName)) return _validPaymentText(text) ? 'PAYTM_NOTIFICATION' : null;
    if (_navi.contains(packageName)) return _validPaymentText(text) ? 'NAVI_NOTIFICATION' : null;
    if (_amazon.contains(packageName)) return _validPaymentText(text) ? 'AMAZON_PAY_NOTIFICATION' : null;
    if (_cred.contains(packageName)) return _validPaymentText(text) ? 'CRED_NOTIFICATION' : null;
    // Banks frequently deliver SMS through the device's default SMS app,
    // whose package name varies by manufacturer. Validate the message body
    // instead of depending on one exact messaging package.
    if (_messages.contains(packageName) || BankNotificationValidator.isValid(text)) {
      return BankNotificationValidator.isValid(text) ? 'BANK_NOTIFICATION' : null;
    }
    return null;
  }

  static bool _validPaymentText(String text) {
    final value = text.toLowerCase();
    final amount = RegExp(r'₹|rs\.?|inr|\b\d+[,.]\d{1,2}\b').hasMatch(value);
    final completed = RegExp(r'paid\s+you|you\s+paid|paid\s+(?:₹|rs\.?|inr)?\s*[0-9][0-9,.]*\s+(?:to|at)|payment successful|debited|credited|refund|refunded|reversal|transaction id|upi').hasMatch(value);
    final rejected = RegExp(r'failed|declined|cancelled|canceled|pending|payment request|collect request|open google pay').hasMatch(value);
    return amount && completed && !rejected;
  }
}
