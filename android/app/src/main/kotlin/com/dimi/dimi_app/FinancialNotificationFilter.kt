package com.dimi.dimi_app

object FinancialNotificationFilter {
    private val paymentPackages = setOf("com.google.android.apps.nbu.paisa.user", "com.google.android.apps.walletnfcrel", "com.phonepe.app", "net.one97.paytm", "com.naviapp", "com.amazon.mShop.android.shopping", "com.dreamplug.androidapp")
    private val amount = Regex("₹|rs\\.?|inr|\\b\\d+[,.]\\d{1,2}\\b", RegexOption.IGNORE_CASE)
    private val sensitiveNoise = Regex("otp|one[- ]time password|verification code|login code|password", RegexOption.IGNORE_CASE)

    fun isPotentialSource(packageName: String, defaultSmsPackage: String?): Boolean =
        packageName.lowercase() in paymentPackages || packageName == "com.google.android.apps.messaging" || packageName == defaultSmsPackage

    fun isRelevant(packageName: String, rawText: String, defaultSmsPackage: String? = null): Boolean {
        val text = rawText.replace("\u20B9", "INR ")
        if (text.isBlank() || sensitiveNoise.containsMatchIn(text)) return false
        val packageId = packageName.lowercase()
        val paymentSource = packageId in paymentPackages
        if (paymentSource) {
            val completed = Regex("paid\\s+you|you\\s+paid|paid\\s+(?:₹|rs\\.?|inr)?\\s*[0-9][0-9,.]*\\s+(?:to|at)|payment successful|debited|credited|refund|refunded|reversal|transaction id|upi", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val rejected = Regex("failed|declined|cancelled|canceled|pending|payment request|collect request|open google pay", RegexOption.IGNORE_CASE).containsMatchIn(text)
            return amount.containsMatchIn(text) && completed && !rejected
        }
        // Bank SMS messages can come from the device's default SMS app,
        // whose package differs across Android manufacturers. Use the
        // message shape rather than assuming Google's messaging package.
        if (packageId == "com.google.android.apps.messaging" || packageId == defaultSmsPackage) {
            val account = Regex("a/c|account|bank|\\bx+\\d{2,}", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val direction = Regex("debited|credited|withdrawn|deposited|received", RegexOption.IGNORE_CASE).containsMatchIn(text)
            val context = Regex("upi|txn|transaction|ref|utr|bal|balance|dt\\b|date", RegexOption.IGNORE_CASE).containsMatchIn(text)
            return amount.containsMatchIn(text) && account && direction && context
        }
        return false
    }

}
