package com.dimi.dimi_app

object FinancialNotificationFilter {
    private val amount = Regex("₹|rs\\.?|inr|\\b\\d+[,.]\\d{1,2}\\b", RegexOption.IGNORE_CASE)
    private val financial = Regex("paid|pay|debit|debited|credit|credited|received|payment|spent|sent|withdrawn|refund|refunded|reversal|upi|a/c|account", RegexOption.IGNORE_CASE)
    private val sensitiveNoise = Regex("otp|one[- ]time password|verification code|login code|password", RegexOption.IGNORE_CASE)

    fun isRelevant(packageName: String, text: String): Boolean {
        if (text.isBlank() || sensitiveNoise.containsMatchIn(text)) return false
        val packageId = packageName.lowercase()
        val paymentSource = packageId in setOf("com.google.android.apps.nbu.paisa.user", "com.google.android.apps.walletnfcrel", "com.phonepe.app", "net.one97.paytm", "com.naviapp", "com.amazon.mShop.android.shopping", "com.dreamplug.androidapp")
        if (paymentSource) {
            val completed = Regex("paid\\s+you|you\\s+paid|paid\\s+(?:₹|rs\\.?|inr)?\\s*[0-9][0-9,.]*\\s+(?:to|at)|payment successful|debited|credited|refund|refunded|reversal|transaction id|upi", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val rejected = Regex("failed|declined|cancelled|canceled|pending|payment request|collect request|open google pay", RegexOption.IGNORE_CASE).containsMatchIn(text)
            return amount.containsMatchIn(text) && completed && !rejected
        }
        // Bank SMS messages can come from the device's default SMS app,
        // whose package differs across Android manufacturers. Use the
        // message shape rather than assuming Google's messaging package.
        if (packageId == "com.google.android.apps.messaging" || isBankMessage(text)) {
            val account = Regex("a/c|account|bank|\\bx+\\d{2,}", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val direction = Regex("debited|credited|withdrawn|deposited|received", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val context = Regex("upi|txn|transaction|ref|utr|bal|balance|dt\\b|date", RegexOption.IGNORE_CASE).containsMatchIn(text)
            return amount.containsMatchIn(text) && account && direction && context
        }
        return false
    }

    private fun isBankMessage(text: String): Boolean {
        val account = Regex("a/c|account|bank|\\bx+\\d{2,}", RegexOption.IGNORE_CASE).containsMatchIn(text)
        val direction = Regex("debited|credited|withdrawn|deposited|received", RegexOption.IGNORE_CASE).containsMatchIn(text)
        val context = Regex("upi|txn|transaction|ref|utr|bal|balance|dt\\b|date", RegexOption.IGNORE_CASE).containsMatchIn(text)
        return amount.containsMatchIn(text) && account && direction && context
    }
}
