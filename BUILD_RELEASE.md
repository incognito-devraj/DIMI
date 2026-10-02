# Building DIMI — Release Guide

## Prerequisites

- Flutter stable channel installed and on PATH
- Android SDK / `adb` on PATH
- `D:\Software\DIMI Secrets\dimi-release-key.jks` present (the release keystore)
- `android/key.properties` present (gitignored — contains keystore path + passwords)
- Supabase credentials ready to pass as `--dart-define` flags (see below)

> ⚠️  **Never commit** `android/key.properties`, the `.jks` file, or the
> `SUPABASE_PUBLISHABLE_KEY` value.  Back up the keystore to a second location
> (USB drive, encrypted cloud storage).  Losing it means you can never update
> the app.

---

## Development run (debug, offline-safe)

The app runs fully offline without Supabase credentials — sign-in is simply
disabled.  For a dev run with Google sign-in working, pass the credentials:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://miukfilerxujorkyceed.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your_publishable_key>
```

---

## Release APK — arm64 only (production)

This is the standard release build.  Produces `dimi-arm64.apk`.

```powershell
flutter build apk --release `
  --target-platform android-arm64 `
  --obfuscate `
  --split-debug-info=build/symbols `
  --dart-define=SUPABASE_URL=https://miukfilerxujorkyceed.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your_publishable_key>
```

After the build completes, rename and copy the APK:

```powershell
Copy-Item build\app\outputs\flutter-apk\app-release.apk `
          build\app\outputs\flutter-apk\dimi-arm64.apk
```

Generate a SHA-256 checksum:

```powershell
Get-FileHash build\app\outputs\flutter-apk\dimi-arm64.apk -Algorithm SHA256 `
  | Select-Object -ExpandProperty Hash `
  | Out-File build\app\outputs\flutter-apk\dimi-arm64.apk.sha256
```

> Keep `build/symbols/` — you need it to read crash stack traces from
> Firebase Crashlytics or logcat.  Do **not** commit it; add to `.gitignore`
> if it appears there.

---

## Test the release build on a real phone

1. Enable Developer Options + USB Debugging on your phone.
2. Connect via USB and verify: `adb devices`
3. Install the release APK:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\dimi-arm64.apk
   ```
4. Check logcat for errors: `adb logcat | Select-String "DIMI\|flutter\|E/"` 
5. Tap **Sign in with Google** → confirm the OAuth flow completes and returns
   to the app.
6. Enable Airplane mode and confirm the app still opens (offline mode).

---

## Release App Bundle (Play Store only — not for direct APK distribution)

```powershell
flutter build appbundle --release `
  --obfuscate `
  --split-debug-info=build/symbols `
  --dart-define=SUPABASE_URL=https://miukfilerxujorkyceed.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your_publishable_key>
```

---

## GitHub Release checklist

1. Commit all changes on `main`.
2. Tag: `git tag v1.0.0 && git push origin v1.0.0`
3. Attach `dimi-arm64.apk` and `dimi-arm64.apk.sha256` to the GitHub Release.
4. Permanent latest download link (use on website):
   `https://github.com/incognito-devraj/DIMI/releases/latest/download/dimi-arm64.apk`

---

## Troubleshooting

### "Google sign-in is unavailable"
The APK was built without the Supabase `--dart-define` flags.  Rebuild with
them included.

### OAuth redirect not working
Verify in Supabase dashboard → Authentication → URL Configuration:
- Redirect URL: `com.dimi.dimi://login-callback/`

### R8 / missing class errors
Add a `-keep` rule for the affected class in `android/app/proguard-rules.pro`,
then rebuild.

### Sharing the APK
Once built, the credentials are baked into the APK binary.  Anyone who
installs it gets Google sign-in working automatically — no extra steps needed.
