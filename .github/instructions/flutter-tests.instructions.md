---
applyTo: "test/**/*.dart,integration_test/**/*.dart"
description: "Use when adding or changing unit, widget, or integration tests. Covers the project's Flutter test conventions and Firebase Emulator setup."
---

# Testing conventions

- Follow the existing test organization and naming: unit/widget tests live under `test/`; end-to-end Firebase flows live under `integration_test/` and use the existing helpers and page objects where appropriate.
- Prefer focused tests that verify observable behavior and important edge cases. Keep test data deterministic and isolated; clean up created Firebase records and sign out between integration-test cases.
- Use the existing Firebase Auth and Firestore mocks/fakes for tests that do not need real emulator behavior. Do not connect tests to production Firebase.
- Integration tests require Firebase Emulators. Follow `docs/building.md` and the repository's test helper/script for emulator startup, device selection, and emulator endpoints; do not assume an emulator is running.
- When a change affects behavior, add or update the relevant test. Run the focused test first, then `flutter test` for broader changes. Run integration tests only when emulator prerequisites are available.
- Avoid flaky timing assumptions and arbitrary delays; wait for explicit UI or state conditions using Flutter test APIs.
