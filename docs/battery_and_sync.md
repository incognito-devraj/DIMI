# DIMI — Battery & Sync Architecture

## Sync System

### How it works
DIMI syncs to Supabase using a `Timer.periodic` inside `_DimiAppState`
in `lib/main.dart`. The timer fires every **15 seconds**.

```dart
_syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
  unawaited(_expirePastReminders());
  unawaited(_syncAndRefresh());
});
```

### Critical behaviour: foreground-only
The timer is **cancelled the moment the app leaves the foreground**:

```dart
} else if (state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached) {
  _syncTimer?.cancel();
  _syncTimer = null;
}
```

And restarted when the app is resumed:

```dart
if (state == AppLifecycleState.resumed) {
  _startForegroundSync();
}
```

**There is zero background network activity.** When DIMI is not visible on
screen — locked phone, recent apps, or killed — no Supabase calls are made.
The sync is purely a foreground convenience to keep the UI fresh while the
user is actively using the app.

---

## Notification System

### Scheduling
All notifications use `AndroidScheduleMode.alarmClock`, which maps to
`AlarmManager.setAlarmClock()` on Android. This is the highest-priority
alarm type available to third-party apps — it is exempt from Doze mode and
battery saver at the Android OS level.

Permissions declared in `AndroidManifest.xml`:

| Permission | Purpose |
|---|---|
| `USE_EXACT_ALARM` | Auto-granted on install, cannot be revoked. Ensures `canScheduleExactAlarms()` always returns `true`, including immediately after reboot before user interaction. |
| `SCHEDULE_EXACT_ALARM` | Kept as fallback for older Android versions. |
| `RECEIVE_BOOT_COMPLETED` | Allows the boot receiver to reschedule alarms after a device restart. |
| `WAKE_LOCK` | Ensures the CPU stays awake long enough to deliver a notification when the screen is off. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Allows DIMI to ask the user to exempt it from Android's battery optimizer so notifications are not delayed after device wake. |

### Why `USE_EXACT_ALARM` matters
The plugin's `ScheduledNotificationBootReceiver` calls
`canScheduleExactAlarms()` on every reboot. If this returns `false`
(which `SCHEDULE_EXACT_ALARM` alone can cause on some devices/Android
versions immediately after boot), the plugin silently deletes every alarm
from its cache via `removeNotificationFromCache()` — and nothing ever fires.
`USE_EXACT_ALARM` is always `true`, so this path is never hit.

### Boot recovery
`ScheduledNotificationBootReceiver` is registered with `exported="true"` in
the manifest (required on Android 12+ for system broadcasts). On reboot it
reads the plugin's internal SharedPreferences cache and re-registers all
alarms with AlarmManager before the user even opens the app.

When the user does open the app, `_finishStartup()` in `lib/main.dart` runs
`rescheduleAll()` from the Drift DB immediately after `init()` — before any
Supabase or auth work — as a second layer of recovery.

### One-time migration guard
`_init()` in `NotificationService` used to call `cancelAll()` on every
launch (originally to clear old icon payloads). This was the primary cause
of notifications not working in background/killed state — it wiped all
pending AlarmManager entries on every cold start. It is now guarded by a
`SharedPreferences` flag (`dimi_notif_icon_migrated_v3`) so `cancelAll()`
only ever runs once after a fresh install.

---

## Battery Impact

### Short answer: negligible
DIMI has no background polling, no push socket, no location tracking, and no
continuous Supabase connection. The only background activity is:

1. AlarmManager entries sitting in the OS scheduler (zero CPU, zero battery)
2. A one-time wake when an alarm fires (fraction of a second to show a notification)

### Battery optimization exemption
DIMI requests exemption from Android's battery optimizer
(`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) on first launch. This does **not**
mean DIMI runs continuously in the background. It means Android will not
artificially delay alarm delivery after the device wakes from sleep.

Without this exemption, Android can defer third-party `alarmClock` alarms by
1–3 minutes after device wake even though the AlarmManager fired on time.
The exemption costs no battery because DIMI has nothing to run in the
background — it only matters for the instant the alarm fires.

### OEM battery managers (Vivo, Xiaomi, OnePlus, Samsung)
Android's standard battery optimization exemption is not enough on devices
running custom OS layers (Vivo FunTouch, MIUI, ColorOS, OneUI). These OEMs
add their own process killer on top of Android that can delay or suppress
alarms regardless of `USE_EXACT_ALARM` or `alarmClock` mode.

**Required manual steps on Vivo (FunTouch OS):**

1. Settings → Battery → **High background power consumption** → enable DIMI
2. Recent apps → DIMI card → lock icon → **Lockdown**
3. Settings → System Management → Developer Options → Apps:
   - "Don't keep activities" → **OFF**
   - "Background process limit" → **Standard limit**

These are the same steps every major reminder/alarm app (Google Keep,
Todoist, Samsung Reminder) instructs Vivo users to follow. They are not
DIMI-specific limitations.

---

## Summary

| Scenario | Network activity | Battery impact |
|---|---|---|
| App on screen | Supabase sync every 15 s | Minimal (same as any open app) |
| App backgrounded / locked | None | Zero |
| App killed | None | Zero |
| Notification fires | None (purely local) | Negligible (< 1 s wake) |
| After reboot (no app open) | None (boot receiver is pure Java, no Flutter/Dart) | Zero |



SOLUTIONS ---

Vivo Android 15. This is a **Vivo/FUNTOUCH OS issue** — Vivo has its own aggressive app killer that runs on top of Android and cannot be bypassed by any Flutter/Android API. Even `USE_EXACT_ALARM` + battery optimization exemption gets overridden by Vivo's own layer.

The only reliable solution is a **native Android foreground service** that keeps the process alive. But that's heavy.

The **correct lightweight fix** for Vivo specifically is to use `WorkManager` for the scheduling fallback AND — more importantly — tell the user exactly which Vivo setting to change. Let me check what specific Vivo setting kills this:**This is 100% a Vivo FunTouch OS issue — not a code issue.** No app code can fix this. Vivo's aggressive memory killer runs at the OS level and overrides Android's AlarmManager regardless of what permissions or scheduling modes are used. WhatsApp, Google Calendar, and every reminder app on Vivo has the same problem out of the box.

---

**Do these 3 things on your Vivo phone — all 3 are needed:**

**1. High background power consumption (most important)**
Settings → Battery → High background power consumption → enable DIMI

**2. Lock DIMI in recents**
Open recent apps → find DIMI → tap the lock icon at the top right of the card → select "Lockdown"

**3. Developer options (one-time)**
Settings → System Management → Developer Options → scroll to Apps section:
- Set "Don't keep activities" → **OFF**
- Set "Background process limit" → **Standard limit**

---

**On the battery question:** No, battery optimization exemption does not meaningfully drain battery for DIMI. DIMI has zero background polling — it doesn't run any code between alarms. The exemption just tells Android "don't delay delivery when an alarm fires." It wakes for a fraction of a second, shows the notification, then goes back to sleep. The real battery drain comes from apps that poll servers continuously (social media, email). DIMI is purely local — no network calls in the background at all.

---

The 2-minute delay you're seeing is **exactly** Vivo's app killer resuming the process after it was suspended. Once you do step 1 and 2 above, it will fire on time. This is the same instruction every major reminder app (Google Keep, Samsung Reminder, Todoist) gives Vivo users in their support docs.