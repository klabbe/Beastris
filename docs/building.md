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
