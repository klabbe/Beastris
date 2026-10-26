---
applyTo: "pubspec.yaml,pubspec.lock,android/settings.gradle.kts,android/build.gradle.kts,android/app/build.gradle.kts,android/gradle/wrapper/gradle-wrapper.properties,ios/Podfile,ios/Podfile.lock"
description: "Use when auditing, updating, adding, or removing Flutter/Dart packages or Android/iOS build dependencies. Keep dependencies on current stable releases while validating compatibility and app behavior."
---

# Dependency update policy

- Keep direct dependencies and platform build tooling on current stable releases. When doing dependency maintenance, audit outdated Flutter/Dart packages and relevant Android/iOS tooling rather than waiting for unrelated feature work.
- Prefer the latest stable versions, not prereleases, dev builds, or release candidates. Do not upgrade a dependency solely because a newer version exists: first check SDK constraints, platform support, changelogs, breaking changes, and interactions with other packages.
- Update `pubspec.yaml` constraints intentionally and regenerate `pubspec.lock` with Pub. Keep the lockfile committed so builds remain reproducible. Do not manually edit lockfile versions.
- Upgrade compatible patch/minor releases together when practical. Treat major-version upgrades, Flutter/Dart SDK changes, Firebase/FlutterFire migrations, and Android Gradle/AGP/Kotlin changes as focused migrations: explain the impact, make required source/config changes, and validate before proceeding to unrelated work.
- If constraints block a newer stable release, identify the blocking package or SDK constraint. Do not force incompatible overrides or loosen constraints blindly; either perform the necessary migration or clearly report what remains pinned and why.
- After dependency updates, run `flutter pub get`, `flutter analyze`, and `flutter test`. Also build the affected targets (at minimum Android debug; release/app bundle when release configuration or native build dependencies changed). Run relevant integration tests when backend/plugin behavior changes and their Firebase Emulator prerequisites are available.
- Review the final dependency diff and `flutter pub outdated` output. Report upgraded packages, intentionally deferred upgrades with their blockers, and any test/build warnings. Do not bump the app's version or publish/release unless explicitly requested.
