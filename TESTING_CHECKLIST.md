# DIMI Testing Checklist - Post Reboot Fix

## Installation & Setup

### Test APK Location
- **File**: `DIMI_reboot-fix_2026-11-08_2038.apk`
- **Size**: 39.4 MB
- **Build Date**: November 8, 2026 20:35
- **Commit**: 81964d3

### Installation Steps
```bash
# Install via ADB
adb install -r DIMI_reboot-fix_2026-11-08_2038.apk

# Or transfer to phone and install manually
adb push DIMI_reboot-fix_2026-11-08_2038.apk /sdcard/Download/
```

---

## Critical Test Scenarios

### 🔴 Test 1: Reboot Alarm Stagger (PRIMARY FIX)

**Objective**: Verify overdue alarms fire 2 seconds apart, not simultaneously

**Steps**:
1. Open DIMI and create 5 reminders:
   - Reminder 1: Current time + 2 minutes
   - Reminder 2: Current time + 3 minutes
   - Reminder 3: Current time + 4 minutes
   - Reminder 4: Current time + 5 minutes
   - Reminder 5: Current time + 6 minutes

2. Wait 1 minute, then **reboot the phone immediately**

3. Wait for reboot to complete, but **DO NOT unlock** until 10 minutes after the first reminder time

4. Unlock with PIN

**Expected Result**:
- ✅ Notifications appear one-by-one, 2 seconds apart
- ✅ First notification appears immediately after unlock
- ✅ Subsequent notifications follow at 2-second intervals
- ✅ All 5 notifications are delivered (no loss)

**Failure Indicators**:
- ❌ All 5 notifications appear at once (old bug)
- ❌ Some notifications are missing
- ❌ Notifications appear but don't make sound

**Status**: [ ] PASS / [ ] FAIL

**Notes**:
```
Time of first notification: ________________
Time of last notification:  ________________
Total delivery span:        ________________ (should be ~8-10 seconds)
```

---

### 🔴 Test 2: Ghost Alarm Prevention

**Objective**: Verify deleted alarms don't reappear after reboot

**Steps**:
1. Create 3 reminders:
   - "Keep this one" - tomorrow at 10 AM
   - "Delete me 1" - tomorrow at 11 AM
   - "Delete me 2" - tomorrow at 12 PM

2. Delete "Delete me 1" and "Delete me 2"

3. **Force kill the DIMI app** immediately after deletion:
   ```bash
   adb shell am force-stop com.dimi.dimi_app
   ```

4. Reboot the phone

5. After reboot, launch DIMI and check the reminders list

**Expected Result**:
- ✅ Only "Keep this one" exists
- ✅ Deleted reminders do NOT reappear
- ✅ No phantom notifications for deleted reminders

**Failure Indicators**:
- ❌ Deleted reminders reappear in the list
- ❌ Notifications fire for deleted reminders

**Status**: [ ] PASS / [ ] FAIL

**Notes**:
```
Reminders visible after reboot: ________________
Any ghost notifications: YES / NO
```

---

### 🔴 Test 3: Stale Alarm Cleanup

**Objective**: Verify alarms older than 24 hours are pruned

**Setup Note**: This test requires either waiting 24+ hours OR manually editing SharedPreferences

**Option A - Wait Method**:
1. Create a reminder for "right now"
2. Let it fire and complete
3. Wait 25 hours
4. Reboot the phone
5. Launch DIMI

**Option B - Manual Method** (requires rooted device or debug build):
1. Create a reminder for tomorrow
2. Use adb to edit device-protected SharedPreferences and backdate the trigger time by 25 hours
3. Reboot
4. Launch DIMI

**Expected Result**:
- ✅ Stale alarm does not fire
- ✅ No notification appears for 25-hour-old alarm
- ✅ App logs show cleanup occurred (check logcat)

**Failure Indicators**:
- ❌ Old alarm fires after reboot
- ❌ App crashes due to malformed alarm data

**Status**: [ ] PASS / [ ] FAIL / [ ] SKIPPED

**Notes**:
```
Method used: Wait / Manual
Result: ________________
```

---

### 🟡 Test 4: Normal Alarm Delivery (Regression Check)

**Objective**: Verify the fix doesn't break normal, on-time alarm delivery

**Steps**:
1. Create a reminder for 2 minutes from now
2. Lock the phone
3. Wait for the alarm time
4. **Do not reboot** - this is testing normal delivery

**Expected Result**:
- ✅ Phone wakes up at the correct time
- ✅ Full-screen reminder appears immediately
- ✅ Sound/vibration plays correctly
- ✅ "Mark Done" and "Snooze" buttons work

**Failure Indicators**:
- ❌ Alarm doesn't fire on time
- ❌ Black screen appears instead of reminder
- ❌ No sound/vibration
- ❌ Can't interact with buttons

**Status**: [ ] PASS / [ ] FAIL

**Notes**:
```
Scheduled time: ________________
Actual fire time: ________________
Delay: ________________
```

---

### 🟡 Test 5: Planner Events

**Objective**: Verify planner event notifications work correctly

**Steps**:
1. Create a planner event for 3 minutes from now
2. Reboot the phone
3. Wait through reboot and unlock after the event time

**Expected Result**:
- ✅ Planner notification appears after unlock
- ✅ Shows correct event title and time
- ✅ Full-screen activity launches correctly

**Status**: [ ] PASS / [ ] FAIL

---

### 🟡 Test 6: YouTube Tick Off Reminders

**Objective**: Verify YouTube playlist reminders work correctly

**Steps**:
1. Add a YouTube playlist with "Tick Off" reminders enabled
2. Set a reminder for 2 minutes from now
3. Lock the phone and wait

**Expected Result**:
- ✅ YouTube reminder fires on time
- ✅ Shows video thumbnail and title
- ✅ Tapping opens the correct video

**Status**: [ ] PASS / [ ] FAIL

---

### 🟢 Test 7: Multiple Reboot Cycles

**Objective**: Verify fix remains stable across multiple reboots

**Steps**:
1. Create 2 reminders for tomorrow
2. Reboot → Launch app → Close app
3. Reboot → Launch app → Close app  
4. Reboot → Launch app → Check reminders

**Expected Result**:
- ✅ Reminders persist correctly
- ✅ No duplicates appear
- ✅ Reminder count remains at 2

**Status**: [ ] PASS / [ ] FAIL

---

### 🟢 Test 8: Offline Mode After Reboot

**Objective**: Verify alarms work when Supabase is unreachable

**Steps**:
1. Enable Airplane Mode
2. Create 2 reminders in offline mode
3. Reboot with Airplane Mode still ON
4. Unlock and wait for reminder times

**Expected Result**:
- ✅ Reminders fire correctly in offline mode
- ✅ No sync errors block alarm delivery
- ✅ App doesn't crash waiting for network

**Status**: [ ] PASS / [ ] FAIL

---

## Additional Checks

### Device Compatibility
- [ ] Test on Android 10
- [ ] Test on Android 11
- [ ] Test on Android 12
- [ ] Test on Android 13+
- [ ] Test on Samsung device (One UI)
- [ ] Test on Google Pixel (Stock Android)
- [ ] Test on other OEM (Xiaomi/OnePlus/Oppo)

### Edge Cases
- [ ] Alarm fires while on a call
- [ ] Alarm fires during video playback
- [ ] Multiple alarms with same time
- [ ] Alarm during system time change
- [ ] Alarm during timezone change
- [ ] Alarm during app update

### UI/UX Verification
- [ ] Full-screen activity shows correctly
- [ ] Notification shade fallback appears
- [ ] Mark Done works correctly
- [ ] Snooze 5 min works correctly
- [ ] Notification sound can be customized
- [ ] Vibration pattern is consistent

---

## Regression Testing

### Features That Should Still Work
- [ ] Create new reminders
- [ ] Edit existing reminders
- [ ] Delete reminders
- [ ] Snooze functionality
- [ ] Notification sound selection
- [ ] Daily recurring reminders
- [ ] Planner events
- [ ] YouTube playlist integration
- [ ] Sync with Supabase
- [ ] Offline mode
- [ ] App updates

---

## Performance Checks

### Battery Impact
- Check battery usage after 24 hours with 10 active reminders
- Expected: < 2% battery drain per day

### Memory Usage
- Monitor memory while multiple reminders are active
- Expected: No memory leaks, stable usage

### APK Size
- Current: 39.4 MB
- Acceptable: < 50 MB

---

## Logs to Collect

During testing, capture logs using:
```bash
# Start logcat before testing
adb logcat -c  # Clear old logs
adb logcat | grep -E "(DimiAlarm|DimiScheduled|DimiBoot|DIMI)" > dimi_test_logs.txt

# Or on Windows PowerShell
adb logcat | Select-String "(DimiAlarm|DimiScheduled|DimiBoot|DIMI)" > dimi_test_logs.txt
```

Look for these log markers:
- `[DimiAlarm] scheduled #` - Alarm was scheduled
- `[DimiAlarm] cancel failed` - Cancellation error
- `[DimiAlarm] cleanup` - Stale entry cleanup occurred
- `DimiBootReceiver` - Boot restoration triggered
- `DimiScheduledReceiver` - Alarm fired

---

## Sign-Off

### Primary Tester
- **Name**: ________________
- **Date**: ________________
- **Device**: ________________
- **Android Version**: ________________

### Critical Tests Status
- Test 1 (Stagger): [ ] PASS / [ ] FAIL
- Test 2 (Ghost Prevention): [ ] PASS / [ ] FAIL  
- Test 3 (Stale Cleanup): [ ] PASS / [ ] FAIL
- Test 4 (Normal Delivery): [ ] PASS / [ ] FAIL

### Overall Assessment
- [ ] APPROVED FOR PRODUCTION
- [ ] NEEDS MINOR FIXES
- [ ] NEEDS MAJOR FIXES
- [ ] NOT READY

### Notes/Issues Found
```
[Add any issues discovered during testing]
```

---

## Production Deployment Checklist

Once testing is complete and approved:

- [ ] Update version number in `pubspec.yaml`
- [ ] Update version code in `android/app/build.gradle`
- [ ] Create git tag (e.g., `v1.0.3`)
- [ ] Build production APK with signing keys
- [ ] Test signed APK on clean device
- [ ] Prepare release notes
- [ ] Upload to Play Store (or distribution method)
- [ ] Monitor crash reports for 48 hours
- [ ] Verify no increase in crash rate

---

**Document Version**: 1.0  
**Created**: November 8, 2026  
**Last Updated**: November 8, 2026
