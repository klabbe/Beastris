#!/bin/bash
# Run integration tests against Firebase Emulators.
# Usage: ./scripts/run_tests.sh [test_file] [device]
#
# Examples:
#   ./scripts/run_tests.sh                          # all tests, auto-detect device
#   ./scripts/run_tests.sh auth_service_test.dart    # specific test file
#   ./scripts/run_tests.sh auth_service_test.dart RFCW60H8EJJ  # specific device

set -e
cd "$(dirname "$0")/.."

TEST_FILE="${1:-}"
DEVICE="${2:-}"

# Auto-detect device if not specified
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(flutter devices --machine 2>/dev/null | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [[ -z "$DEVICE" ]]; then
    echo "No device found. Connect a device or start an emulator."
    exit 1
  fi
  echo "Auto-detected device: $DEVICE"
fi

# Check emulators are running
if ! curl -s http://localhost:9099 > /dev/null 2>&1; then
  echo "Firebase Auth emulator not running on port 9099."
  echo "Start it with: firebase emulators:start"
  exit 1
fi

# Set up adb reverse so physical Android devices can reach emulators via 10.0.2.2
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
if [[ -x "$ADB" ]]; then
  echo "Setting up adb reverse port forwarding..."
  "$ADB" -s "$DEVICE" reverse tcp:9099 tcp:9099 2>/dev/null || true
  "$ADB" -s "$DEVICE" reverse tcp:8080 tcp:8080 2>/dev/null || true
fi

# Build target path
if [[ -n "$TEST_FILE" ]]; then
  TARGET="integration_test/$TEST_FILE"
else
  TARGET="integration_test/"
fi

echo "Running: $TARGET on $DEVICE"
flutter test "$TARGET" -d "$DEVICE"
