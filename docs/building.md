# Building & Running

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
- For Android: Android SDK with accepted licenses
- For iOS/macOS: Xcode (full installation)
- For Web: Chrome

## Run in Debug Mode

```bash
# Web (Chrome)
flutter run -d chrome

# macOS (requires Xcode)
flutter run -d macos

# Android (connect device via USB with USB debugging enabled)
flutter run -d <device-id>

# List available devices
flutter devices
```

## Build Release

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# Web
flutter build web

# macOS
flutter build macos
```

## Android Device Setup

1. On your phone, go to **Settings → About phone**
2. Tap **Build number** 7 times to enable Developer Options
3. Go to **Settings → Developer Options**
4. Enable **USB Debugging**
5. Connect via USB-C cable
6. Accept the "Allow USB debugging?" prompt on the phone
7. Run `flutter devices` to verify the device is detected

## Integration Tests

The project includes integration tests that run against Firebase Emulators (Auth on port 9099, Firestore on port 8080). The same tests work on web, Android, and iOS.

### Structure

```
integration_test/
├── helpers/
│   ├── test_bootstrap.dart    # Firebase init + emulator connection
│   └── test_helpers.dart      # Unique emails, data cleanup utilities
├── pages/
│   ├── menu_page.dart         # Main menu page object
│   ├── auth_dialog_page.dart  # Sign In / Register dialog page object
│   └── profile_dialog_page.dart # Profile edit dialog page object
├── auth_service_test.dart     # AuthService backend tests
├── leaderboard_service_test.dart # LeaderboardService backend tests
└── auth_flow_test.dart        # End-to-end UI auth flow tests
```

### Test Suites

**auth_service_test.dart** — Tests the AuthService directly against emulators:
- Register creates account and Firestore profile
- Duplicate alias is rejected
- Sign in loads profile from Firestore
- Sign out clears state
- Update profile changes alias
- Update to taken alias fails
- Delete account anonymizes leaderboard entries
- Wrong password returns error

**leaderboard_service_test.dart** — Tests the LeaderboardService:
- Submit score creates a Firestore document
- Top 10 are ordered by score
- Deduplication keeps only the best score per user
- Anonymous entries are not deduplicated
- User rank is calculated correctly
- Weekly filter excludes entries older than 7 days
- Best weekly score lookup works
- Missing user returns null

**auth_flow_test.dart** — Full UI flows through page objects:
- Register → verify signed in → sign out
- Sign in with existing account
- Update profile alias through UI
- Delete account through UI

### Running

```bash
# 1. Start Firebase Emulators (keep running in a separate terminal)
firebase emulators:start

# 2. Run tests on web
flutter test integration_test/auth_service_test.dart -d chrome
flutter test integration_test/leaderboard_service_test.dart -d chrome
flutter test integration_test/auth_flow_test.dart -d chrome

# 3. Or run on a connected Android device
flutter test integration_test/auth_service_test.dart -d <device-id>

# Run all integration tests at once
flutter test integration_test/ -d chrome
```

Each test automatically cleans up Firestore data and signs out between runs. No manual data seeding is needed.

## Troubleshooting

### Android SDK license errors

```bash
# Accept all licenses
flutter doctor --android-licenses
```

If `sdkmanager` is not found, install cmdline-tools:
```bash
# Download from https://developer.android.com/studio#command-line-tools-only
# Extract to ~/Library/Android/sdk/cmdline-tools/latest/
# Then accept licenses:
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

### Missing Xcode for macOS builds

Install Xcode from the App Store, then:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```
