# Building DIMI Release APK

Credentials are stored in `.env` (gitignored). The file already exists locally
with the correct values — do not commit it.

## Run (development)

```powershell
flutter run --dart-define-from-file=.env
```

## Release APK

```powershell
flutter build apk --release --dart-define-from-file=.env
```

The produced APK is at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Install directly on a device:
```powershell
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Release App Bundle (Play Store)

```powershell
flutter build appbundle --release --dart-define-from-file=.env
```

## Troubleshooting

### "Google sign-in is unavailable"
The APK was built without the `.env` file. Rebuild using the commands above.

### OAuth redirect not working
Verify in Supabase dashboard → Authentication → URL Configuration:
- Redirect URL: `com.dimi.dimi://login-callback/`

### Sharing the APK
Once built, the credentials are baked into the APK binary.
Anyone who installs the APK gets Google sign-in working automatically — 
no extra steps needed on their device.
