import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beastblocks/models/game_history.dart';
import 'package:beastblocks/services/leaderboard_service.dart';

import 'helpers/test_bootstrap.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late LeaderboardService leaderboard;

  setUpAll(() async {
    await testBootstrap();
  });

  setUp(() async {
    await resetTestState();
    leaderboard = LeaderboardService();
  });

  group('LeaderboardService —', () {
    testWidgets('submit score creates document', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      await leaderboard.submitScore(
        GameResult(score: 100, lines: 5, level: 1, date: DateTime.now()),
        'Player1',
        uid: 'uid-1',
        country: 'SE',
      );

      final data = await leaderboard.fetchAllTimeData(uid: 'uid-1');
      expect(data.top10.length, 1);
      expect(data.top10.first.name, 'Player1');
      expect(data.top10.first.score, 100);
      expect(data.top10.first.country, 'SE');
    });

    testWidgets('fetchAllTimeData returns top 10 ordered by score',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Submit 12 entries with unique uids
      for (int i = 1; i <= 12; i++) {
        await leaderboard.submitScore(
          GameResult(score: i * 100, lines: i, level: 1, date: DateTime.now()),
          'Player$i',
          uid: 'uid-$i',
        );
      }

      final data = await leaderboard.fetchAllTimeData();
      expect(data.top10.length, 10);
      expect(data.top10.first.score, 1200); // highest
      expect(data.top10.last.score, 300); // 10th
    });

    testWidgets('deduplication keeps only best score per uid', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Same uid, different scores
      await leaderboard.submitScore(
        GameResult(score: 100, lines: 5, level: 1, date: DateTime.now()),
        'Player1',
        uid: 'uid-dupe',
      );
      await leaderboard.submitScore(
        GameResult(score: 500, lines: 20, level: 5, date: DateTime.now()),
        'Player1',
        uid: 'uid-dupe',
      );

      final data = await leaderboard.fetchAllTimeData(uid: 'uid-dupe');
      final entries = data.top10.where((e) => e.uid == 'uid-dupe').toList();
      expect(entries.length, 1);
      expect(entries.first.score, 500); // best score kept
    });

    testWidgets('anonymous entries (no uid) are not deduplicated',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      await leaderboard.submitScore(
        GameResult(score: 100, lines: 5, level: 1, date: DateTime.now()),
        'Anon1',
      );
      await leaderboard.submitScore(
        GameResult(score: 200, lines: 10, level: 2, date: DateTime.now()),
        'Anon2',
      );

      final data = await leaderboard.fetchAllTimeData();
      expect(data.top10.length, 2); // both kept
    });

    testWidgets('userRank is calculated correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Submit 5 entries, different uids and scores
      for (int i = 1; i <= 5; i++) {
        await leaderboard.submitScore(
          GameResult(score: i * 100, lines: i, level: 1, date: DateTime.now()),
          'Player$i',
          uid: 'uid-$i',
        );
      }

      // uid-3 has score 300 → rank 3 (after 500, 400)
      final data = await leaderboard.fetchAllTimeData(uid: 'uid-3');
      expect(data.userRank, isNotNull);
      expect(data.userRank!.$1, 3);
      expect(data.userRank!.$2.score, 300);
    });

    testWidgets('weekly filter excludes old entries', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Submit a recent entry through the service
      await leaderboard.submitScore(
        GameResult(score: 100, lines: 5, level: 1, date: DateTime.now()),
        'RecentPlayer',
        uid: 'uid-recent',
      );

      // Insert an old entry directly in Firestore (10 days ago)
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      await FirebaseFirestore.instance.collection('leaderboard').add({
        'name': 'OldPlayer',
        'score': 500,
        'lines': 20,
        'level': 5,
        'date': oldDate.toIso8601String(),
        'timestamp': oldDate.millisecondsSinceEpoch,
        'uid': 'uid-old',
      });

      final data = await leaderboard.fetchWeeklyData(uid: 'uid-recent');
      expect(data.top10.length, 1); // only the recent entry
      expect(data.top10.first.name, 'RecentPlayer');
    });

    testWidgets('fetchUserBestScoreThisWeek returns best weekly score',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      await leaderboard.submitScore(
        GameResult(score: 100, lines: 5, level: 1, date: DateTime.now()),
        'WeeklyPlayer',
        uid: 'uid-weekly',
      );
      await leaderboard.submitScore(
        GameResult(score: 300, lines: 15, level: 3, date: DateTime.now()),
        'WeeklyPlayer',
        uid: 'uid-weekly',
      );

      final best = await leaderboard.fetchUserBestScoreThisWeek('uid-weekly');
      expect(best, 300);
    });

    testWidgets('fetchUserBestScoreThisWeek returns null when no entries',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final best =
          await leaderboard.fetchUserBestScoreThisWeek('nonexistent-uid');
      expect(best, isNull);
    });
  });
}
