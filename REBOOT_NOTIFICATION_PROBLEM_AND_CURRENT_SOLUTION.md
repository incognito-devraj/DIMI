# DIMI Reboot Notification Problem and Current Solution

## Problem

When a reminder, planner event, or YouTube Tick Off alarm is scheduled and the phone is rebooted before the due time:

- The alarm may not fire while the phone is still locked.
- The phone may show only a normal lock-screen notification instead of the full-screen alarm.
- The full-screen alarm may appear only after the user taps the notification, unlocks the phone, or opens DIMI.
- In some tests, opening DIMI caused the overdue notification to appear a few seconds later because the app recreated the alarm from the local Drift database.
- The original notification may remain in the notification shade and reappear every time the phone is unlocked.
- Multiple notification paths can cause duplicate or delayed delivery.
- Deleted or superseded alarms can reappear if stale native metadata or retry alarms remain.

## Confirmed diagnosis

The alarm delivery path had several competing mechanisms:

1. Flutter scheduled notifications and their boot receiver.
2. DIMI's native AlarmManager receiver.
3. A full-screen Flutter activity.
4. A native Direct Boot activity.
5. Retry alarms that reposted the notification.

The most important failure was native alarm metadata storage. The previous scheduler used `moveSharedPreferencesFrom()` between credential-protected and device-protected storage. During Direct Boot, the boot receiver could not reliably find the scheduled alarm metadata. When DIMI was opened, Drift loaded the reminder and rescheduled it, which made it appear as though opening the app caused the alarm to fire.

The repeated notification behavior was also caused by the backing notification being marked ongoing and by more than one boot-restoration path being active.

## Current solution being applied

### 1. Dedicated device-protected alarm store

Every native alarm is written directly to:

`dimi_alarms_device_v2`

This store is available before the first PIN unlock. Alarm metadata is committed synchronously before the AlarmManager alarm is installed.

The metadata contains:

- notification ID;
- trigger time;
- payload;
- title;
- body;
- notification type.

The previous native store is still read for migration, and the credential-protected store is retained only as a normal-app recovery copy. Direct Boot restoration does not depend on either Flutter or credential-protected storage.

### 2. Native boot restoration

`DimiBootReceiver` restores native alarms from device-protected metadata after:

- `LOCKED_BOOT_COMPLETED`;
- `BOOT_COMPLETED`;
- package replacement;
- supported manufacturer quick-boot events.

Restoration does not start Flutter, read Drift, contact Supabase, or wait for login.

### 3. Native Direct Boot alarm surface

Before the first PIN unlock, the full-screen intent targets `DimiDirectBootActivity`, not Flutter.

This activity:

- uses only native Android UI;
- wakes the screen over the lock screen;
- plays the ringtone;
- supports Snooze 5 min and Mark Done;
- finishes after three rings;
- leaves one ordinary notification afterward;
- queues actions in device-protected storage for Drift reconciliation after unlock.

After the device has been unlocked normally, the existing Flutter full-screen reminder activity remains available.

### 4. Single alarm restoration path

The `flutter_local_notifications` boot receiver was removed for these alarms. DIMI's native boot receiver is the authoritative restoration path. This prevents the native and Flutter schedulers from restoring the same alarm independently.

### 5. Notification lifecycle cleanup

- The full-screen alarm card is no longer marked ongoing.
- Opening either alarm activity clears the visible backing notification immediately.
- The three-ring completion replaces the alarm card with one ordinary shade notification.
- Cancellation removes the native alarm, retry alarm, notification, and stored metadata.

## Local/cloud boundary

Alarm delivery is local-only and must work without Supabase, internet, authentication, or Flutter startup.

Supabase synchronization occurs only after local Drift changes. It is not part of the boot, alarm, or lock-screen delivery path.

## Verification criteria

The solution is considered verified only when all of these pass on the real device:

1. Create a new alarm.
2. Reboot before its due time.
3. Do not open DIMI after reboot.
4. Keep the phone locked past the due time.
5. The native full-screen alarm appears at the scheduled time.
6. It does not require tapping a normal notification first.
7. It does not require opening DIMI.
8. After three rings, one ordinary notification remains.
9. Unlocking does not replay the notification repeatedly.
10. Mark Done and Snooze update local state correctly after DIMI is opened.

## Current verification limitation

The code compiles and the release APK builds, but the real device reboot/Direct Boot behavior has not been independently verified from this development environment. If the fresh build still waits until DIMI is opened, the next required evidence is an Android `logcat` capture covering `DimiBootReceiver`, `DimiAlarmScheduler`, and `DimiScheduledReceiver` during one reboot test.
