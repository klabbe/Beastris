import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beastblocks/models/game_history.dart';
import 'package:beastblocks/models/user_profile.dart';
import 'package:beastblocks/services/auth_service.dart';
import 'package:beastblocks/services/leaderboard_service.dart';

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

  group('AuthService —', () {
    testWidgets('register creates account and Firestore profile',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final auth = AuthService();
      final email = uniqueEmail('register');
      final alias = uniqueAlias('Reg');
      final profile = UserProfile(
        uid: '',
        alias: alias,
        name: 'Test User',
        country: 'SE',
      );

      final error = await auth.register(email, 'password123', profile);

      expect(error, isNull);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.profile, isNotNull);
      expect(auth.profile!.alias, alias);
      expect(auth.profile!.name, 'Test User');
      expect(auth.profile!.country, 'SE');

      // register() now awaits Firestore save — verify immediately
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['alias'], alias);

      await auth.signOut();
      auth.dispose();
    });

    testWidgets('register with duplicate alias fails', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final sharedAlias = uniqueAlias('Dupe');

      // First registration
      final auth1 = AuthService();
      await auth1.register(
        uniqueEmail('dupe1'),
        'password123',
        UserProfile(uid: '', alias: sharedAlias),
      );
      await auth1.signOut();
      auth1.dispose();

      // Second registration with the same alias should fail
      final auth2 = AuthService();
      final error = await auth2.register(
        uniqueEmail('dupe2'),
        'password123',
        UserProfile(uid: '', alias: sharedAlias),
      );

      expect(error, isNotNull);
      expect(error!.toLowerCase(), contains('alias'));
      expect(auth2.isLoggedIn, isFalse);
      auth2.dispose();
    });

    testWidgets('sign in loads profile from Firestore', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Register
      final email = uniqueEmail('signin');
      final alias = uniqueAlias('SignIn');
      final auth = AuthService();
      await auth.register(
        email,
        'password123',
        UserProfile(uid: '', alias: alias, name: 'Test', country: 'NO'),
      );
      await auth.signOut();
      auth.dispose();

      // Sign in with new AuthService instance
      final auth2 = AuthService();
      final error = await auth2.signIn(email, 'password123');

      expect(error, isNull);
      expect(auth2.isLoggedIn, isTrue);
      expect(auth2.profile!.alias, alias);
      expect(auth2.profile!.country, 'NO');

      await auth2.signOut();
      auth2.dispose();
    });

    testWidgets('sign out clears state', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final auth = AuthService();
      await auth.register(
        uniqueEmail('signout'),
        'password123',
        UserProfile(uid: '', alias: uniqueAlias('Out')),
      );

      await auth.signOut();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.profile, isNull);
      auth.dispose();
    });

    testWidgets('update profile changes alias', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final auth = AuthService();
      await auth.register(
        uniqueEmail('update'),
        'password123',
        UserProfile(uid: '', alias: uniqueAlias('Old')),
      );

      final newAlias = uniqueAlias('New');
      final updated = auth.profile!.copyWith(alias: newAlias);
      final error = await auth.updateProfile(updated);

      expect(error, isNull);
      expect(auth.profile!.alias, newAlias);

      await auth.signOut();
      auth.dispose();
    });

    testWidgets('update profile with taken alias fails', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final takenAlias = uniqueAlias('Taken');
      final freeAlias = uniqueAlias('Free');

      // First user takes an alias
      final auth1 = AuthService();
      await auth1.register(
        uniqueEmail('taken1'),
        'password123',
        UserProfile(uid: '', alias: takenAlias),
      );
      await auth1.signOut();
      auth1.dispose();

      // Second user tries to update to the same alias
      final auth2 = AuthService();
      await auth2.register(
        uniqueEmail('taken2'),
        'password123',
        UserProfile(uid: '', alias: freeAlias),
      );

      final updated = auth2.profile!.copyWith(alias: takenAlias);
      final error = await auth2.updateProfile(updated);

      expect(error, isNotNull);
      expect(error!.toLowerCase(), contains('alias'));
      expect(auth2.profile!.alias, freeAlias); // unchanged

      await auth2.signOut();
      auth2.dispose();
    });

    testWidgets('delete account anonymizes leaderboard entries',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final alias = uniqueAlias('Del');

      // Register and submit a leaderboard score
      final auth = AuthService();
      await auth.register(
        uniqueEmail('delete'),
        'password123',
        UserProfile(uid: '', alias: alias),
      );

      final uid = auth.currentUser!.uid;
      final leaderboard = LeaderboardService();
      await leaderboard.submitScore(
        GameResult(score: 500, lines: 10, level: 3, date: DateTime.now()),
        alias,
        uid: uid,
      );

      // Delete account
      final error = await auth.deleteAccount();
      expect(error, isNull);
      expect(auth.isLoggedIn, isFalse);

      // Verify leaderboard entry still exists but uid is cleared
      final data = await leaderboard.fetchAllTimeData(uid: uid);
      expect(data.userRank, isNull); // no entries for deleted uid
      final entry = data.top10.firstWhere((e) => e.name == alias);
      expect(entry.uid, ''); // anonymized

      // Verify Firestore profile is deleted
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      expect(doc.exists, isFalse);

      auth.dispose();
    });

    testWidgets('sign in with wrong password fails', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final email = uniqueEmail('wrongpw');
      final auth = AuthService();
      await auth.register(
        email,
        'password123',
        UserProfile(uid: '', alias: uniqueAlias('WrongPw')),
      );
      await auth.signOut();
      auth.dispose();

      final auth2 = AuthService();
      final error = await auth2.signIn(email, 'wrongpassword');

      expect(error, isNotNull);
      expect(auth2.isLoggedIn, isFalse);
      auth2.dispose();
    });
  });
}
