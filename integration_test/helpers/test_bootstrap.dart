import 'package:beastblocks/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

bool _initialized = false;

/// Override via `--dart-define=EMULATOR_HOST=<ip>` for custom setups.
/// For physical Android devices, the run_tests.sh script sets up
/// `adb reverse` so localhost works without overrides.
const _hostOverride = String.fromEnvironment('EMULATOR_HOST');

String get emulatorHost {
  if (_hostOverride.isNotEmpty) return _hostOverride;
  // With adb reverse set up (see scripts/run_tests.sh), localhost works
  // on both Android emulators and physical devices.
  return 'localhost';
}

/// Initialize Firebase and connect to local emulators.
/// Safe to call multiple times — only initializes once.
Future<void> testBootstrap() async {
  if (_initialized) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Connecting to emulators at $emulatorHost');
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);

  _initialized = true;
}
