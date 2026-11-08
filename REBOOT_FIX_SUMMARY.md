# DIMI Reboot Alarm Fix - November 8, 2026

## Problem Statement

After phone reboot, DIMI alarms exhibited multiple serious issues:

1. **Notification Flooding**: All overdue notifications would fire simultaneously after PIN unlock, overwhelming the user with 5+ notifications at once (all timestamped "Now")
2. **Ghost Alarms**: Deleted or superseded alarms would reappear after reboot because stale metadata wasn't being cleaned up
3. **Delayed Delivery**: Alarms would wake the phone but not render until after unlock, causing missed reminders

## Root Cause Analysis

The existing code already had:
- ✅ DirectBoot-aware receivers (`android:directBootAware="true"`)
- ✅ Device-protected storage for alarm metadata
- ✅ Proper native notification path (no Flutter dependency)

The actual problems were:

1. **`restoreAfterBoot()` had no stagger logic**: All overdue alarms were scheduled to fire at `now + 500ms`, causing them all to fire simultaneously the moment the phone unlocked
2. **No stale alarm cleanup**: Deleted alarms left metadata in SharedPreferences. If the app was killed before `cancel()` completed, the metadata remained forever and would be restored on reboot
3. **No retry alarm cancellation**: When canceling an alarm, the 5-minute retry alarm wasn't being canceled, leading to ghost notifications

## Solution Implemented

### 1. Staggered Overdue Alarm Delivery

**File**: `android/app/src/main/kotlin/com/dimi/dimi_app/DimiAlarmScheduler.kt`

```kotlin
// Spread out overdue alarms by 2 seconds each to prevent simultaneous
// notification flood after unlock. First overdue alarm fires immediately.
var overdueDelaySeconds = 0

for ((key, value) in metadata) {
    // ... 
    val effectiveTrigger = if (triggerAtMillis <= now) {
        now + (overdueDelaySeconds * 2000L) + 500L
        .also { overdueDelaySeconds++ }
    } else {
        triggerAtMillis
    }
}
```

**Impact**: Overdue alarms now fire 2 seconds apart instead of all at once.

### 2. Stale Alarm Pruning

**File**: `android/app/src/main/kotlin/com/dimi/dimi_app/DimiAlarmScheduler.kt`

```kotlin
// If alarm is more than 24 hours old, skip it — it's stale.
// Flutter will reconcile from the database on next app launch.
val ageHours = (now - triggerAtMillis) / (1000 * 60 * 60)
if (ageHours > 24) {
    // Clean up the stale entry
    prefs.edit()
        .remove(PAYLOAD_PREFIX + notifId)
        .remove(METADATA_PREFIX + notifId)
        .apply()
    continue
}
```

**Impact**: Alarms older than 24 hours are automatically cleaned up during restore, preventing ancient ghost alarms from reappearing.

### 3. Startup Cleanup Function

**New Method**: `DimiAlarmScheduler.cleanupStaleEntries()`

Called during app startup to proactively remove stale alarm metadata before any rescheduling occurs.

**Files Modified**:
- `DimiAlarmScheduler.kt`: Added `cleanupStaleEntries()` method
- `MainActivity.kt`: Exposed via MethodChannel as `"cleanupStaleEntries"`
- `lib/services/dimi_alarm_service.dart`: Added `cleanupStaleEntries()` wrapper
- `lib/main.dart`: Calls cleanup before `repairNotificationIds()`

**Impact**: Ghost alarms from deleted/superseded reminders are purged on every app launch.

### 4. Complete Alarm Cancellation

Enhanced the `cancel()` method to also cancel retry alarms:

```kotlin
// Also cancel any pending retry alarm
val retryIntent = Intent(context, DimiRetryReceiver::class.java).apply {
    action = "com.dimi.dimi_app.RETRY_NOTIFICATION.$notifId"
}
val retryPi = PendingIntent.getBroadcast(
    context,
    notifId + 700000000,
    retryIntent,
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
)
am.cancel(retryPi)
retryPi.cancel()
```

**Impact**: When an alarm is canceled, both the primary alarm AND its retry alarm are removed.

## Testing Instructions

### How to Test the Fix

1. **Install the test APK**: `DIMI_reboot-fix_2026-11-08_2038.apk`

2. **Test Scenario 1: Staggered Delivery**
   - Schedule 5+ reminders in the next 5 minutes
   - Reboot the phone immediately
   - Unlock after the scheduled times have passed
   - **Expected**: Notifications appear 2 seconds apart, not all at once

3. **Test Scenario 2: Stale Alarm Cleanup**
   - Schedule a reminder for tomorrow
   - Manually edit SharedPreferences to make it 25 hours old (or wait 25 hours)
   - Reboot
   - **Expected**: Stale alarm does not reappear

4. **Test Scenario 3: Ghost Alarm Prevention**
   - Schedule a reminder
   - Delete it
   - Kill the app before Flutter finishes cleanup
   - Reboot
   - Launch DIMI
   - **Expected**: The deleted alarm does not reappear

## Files Modified

### Native Android (Kotlin)
- `android/app/src/main/kotlin/com/dimi/dimi_app/DimiAlarmScheduler.kt`
- `android/app/src/main/kotlin/com/dimi/dimi_app/MainActivity.kt`

### Flutter/Dart
- `lib/services/dimi_alarm_service.dart`
- `lib/main.dart`

### Build Artifacts
- `DIMI_reboot-fix_2026-11-08_2038.apk` (test build with fixes)

## Deployment Status

- ✅ Code committed: `81964d3`
- ✅ Test APK built and available
- ⏳ Awaiting testing and verification
- ⏳ Production release pending

## Next Steps

1. Test the APK on a physical device with multiple scenarios
2. Verify no regressions in normal alarm delivery
3. Conduct full app audit (Phase 2) to identify any other production readiness issues
4. Tag a new release version (v1.0.3 or v1.1.0)
5. Deploy to production

## Comparison to Last Release

- **Last official release**: `v1.0.2` (commit `d65744f`)
- **Current commit**: `81964d3`
- **Changes since v1.0.2**: 
  - Native full-screen notification improvements
  - Settings page polish
  - **This reboot alarm fix**

---

**Built**: November 8, 2026 20:38
**Commit**: 81964d3
**Status**: Ready for testing
