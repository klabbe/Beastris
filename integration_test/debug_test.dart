import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_bootstrap.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await testBootstrap();
  });

  setUp(() async {
    await resetTestState();
  });

  testWidgets('direct Firebase Auth register', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'directtest@test.com',
        password: 'password123',
      );
      debugPrint('SUCCESS: uid=${cred.user?.uid}');
    } catch (e) {
      debugPrint('EXCEPTION TYPE: ${e.runtimeType}');
      debugPrint('EXCEPTION: $e');
      if (e is FirebaseAuthException) {
        debugPrint('CODE: ${e.code}');
        debugPrint('MESSAGE: ${e.message}');
      }
      rethrow;
    }
  });
}
