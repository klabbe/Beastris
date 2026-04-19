import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'test_bootstrap.dart';

int _counter = 0;

/// Generate a unique email to avoid conflicts between tests.
String uniqueEmail([String prefix = 'test']) {
  _counter++;
  final ts = DateTime.now().millisecondsSinceEpoch;
  return '${prefix}_${ts}_$_counter@test.com';
}

/// Generate a unique alias to avoid conflicts between tests and runs.
String uniqueAlias([String prefix = 'Alias']) {
  _counter++;
  final ts = DateTime.now().millisecondsSinceEpoch;
  return '${prefix}_${ts}_$_counter';
}

/// Clear all Firestore data via the emulator REST API (bypasses security rules).
/// Retries on 503 (emulator sometimes returns UNAVAILABLE transiently).
Future<void> _clearFirestore() async {
  final host = emulatorHost;
  const projectId = 'beastris-game-90b1b';
  final url = Uri.parse(
    'http://$host:8080/emulator/v1/projects/$projectId/databases/(default)/documents',
  );
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) return;
      debugPrint('WARNING: Firestore clear attempt ${attempt + 1}: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('WARNING: Firestore clear attempt ${attempt + 1} error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Clear all Auth emulator accounts via the REST API.
Future<void> _clearAuthAccounts() async {
  final host = emulatorHost;
  const projectId = 'beastris-game-90b1b';
  final url = Uri.parse(
    'http://$host:9099/emulator/v1/projects/$projectId/accounts',
  );
  try {
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      debugPrint('WARNING: Failed to clear Auth emulator accounts: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    debugPrint('WARNING: Auth emulator clear error: $e');
  }
}

/// Sign out the current user if any.
Future<void> signOutIfNeeded() async {
  if (FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
  }
}

/// Full cleanup: sign out + clear Auth accounts.
/// Firestore clearing is skipped on web (CORS prevents emulator REST calls).
/// Tests use unique aliases/emails so they don't depend on a clean Firestore.
Future<void> resetTestState() async {
  await signOutIfNeeded();
  await _clearAuthAccounts();
  // Only clear Firestore from native platforms where http.delete works
  if (!kIsWeb) {
    await _clearFirestore();
  }
}
