// Unit tests for LeaderboardService.
//
// Uses FakeFirebaseFirestore so tests run on the Dart VM with no emulators
// or network. Dates are relative to DateTime.now() so the weekly window
// tests remain valid regardless of when they are run.
//
// Run with: flutter test test/leaderboard_service_test.dart

import 'package:beastris/models/game_history.dart';
import 'package:beastris/services/leaderboard_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late LeaderboardService service;

  final _now = DateTime.now();
  final _threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
  final _tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

  GameResult result({required int score, int lines = 10, int level = 2, DateTime? date}) =>
      GameResult(score: score, lines: lines, level: level, date: date ?? _now);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = LeaderboardService(db: db);
  });

  // submitScore() writes a new document to the leaderboard collection.
  // uid and country are optional and must be omitted (not stored as null)
  // when not provided or empty.
  group('submitScore', () {
    test('saves all fields to Firestore', () async {
      final r = result(score: 1500, lines: 20, level: 5);
      await service.submitScore(r, 'Alice', uid: 'uid-alice', country: 'SE');

      final snap = await db.collection('leaderboard').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['name'], 'Alice');
      expect(data['score'], 1500);
      expect(data['lines'], 20);
      expect(data['level'], 5);
      expect(data['uid'], 'uid-alice');
      expect(data['country'], 'SE');
    });

    test('omits uid and country fields when not provided', () async {
      final r = result(score: 800);
      await service.submitScore(r, 'Anonymous');

      final snap = await db.collection('leaderboard').get();
      final data = snap.docs.first.data();
      expect(data.containsKey('uid'), isFalse);
      expect(data.containsKey('country'), isFalse);
    });

    test('omits country when it is empty string', () async {
      final r = result(score: 600);
      await service.submitScore(r, 'NoCountry', uid: 'uid-x', country: '');

      final snap = await db.collection('leaderboard').get();
      final data = snap.docs.first.data();
      expect(data['uid'], 'uid-x');
      expect(data.containsKey('country'), isFalse);
    });
  });

  // fetchAllTimeData() returns the top 10 distinct players by best score,
  // sorted descending. Players with multiple entries are deduplicated — only
  // their highest score is kept. Anonymous entries (empty uid) are never
  // deduplicated. The caller's own rank across all players is also returned.
  group('fetchAllTimeData', () {
    setUp(() async {
      await _seedEntries(db, [
        _entry('uid-1', 'Alice', 5000, _now),
        _entry('uid-2', 'Bob', 3000, _now),
        _entry('uid-3', 'Carol', 7000, _now),
        _entry('uid-1', 'Alice', 6000, _threeDaysAgo), // Second entry for Alice
      ]);
    });

    test('returns entries sorted by score descending', () async {
      final data = await service.fetchAllTimeData();

      final scores = data.top10.map((e) => e.score).toList();
      expect(scores, orderedEquals(scores.toList()..sort((a, b) => b.compareTo(a))));
    });

    test('deduplicates by uid — keeps only best score per player', () async {
      final data = await service.fetchAllTimeData();

      // Alice appears twice (5000 and 6000) — only 6000 should be kept
      final aliceEntries = data.top10.where((e) => e.uid == 'uid-1').toList();
      expect(aliceEntries.length, 1);
      expect(aliceEntries.first.score, 6000);
    });

    test('returns top10 capped at maxEntries', () async {
      // Add 12 distinct users
      await _seedEntries(db, List.generate(12, (i) => _entry('bulk-$i', 'Player$i', i * 100, _now)));

      final data = await service.fetchAllTimeData();

      expect(data.top10.length, lessThanOrEqualTo(LeaderboardService.maxEntries));
    });

    test('returns userRank when uid is in leaderboard', () async {
      final data = await service.fetchAllTimeData(uid: 'uid-3');

      expect(data.userRank, isNotNull);
      expect(data.userRank!.$1, 1); // Carol has highest score (7000)
      expect(data.userRank!.$2.name, 'Carol');
    });

    test('returns null userRank when uid not in leaderboard', () async {
      final data = await service.fetchAllTimeData(uid: 'unknown-uid');

      expect(data.userRank, isNull);
    });

    test('keeps anonymous entries (empty uid) without deduplication', () async {
      await db.collection('leaderboard').add(_entry('', 'Anon1', 100, _now));
      await db.collection('leaderboard').add(_entry('', 'Anon2', 200, _now));

      final data = await service.fetchAllTimeData();

      final anonEntries = data.top10.where((e) => e.uid.isEmpty).toList();
      expect(anonEntries.length, 2);
    });
  });

  // fetchWeeklyData() applies the same top-10 / deduplication logic as
  // fetchAllTimeData() but filters to entries from the last 7 days only.
  group('fetchWeeklyData', () {
    setUp(() async {
      await _seedEntries(db, [
        _entry('uid-1', 'RecentPlayer', 4000, _threeDaysAgo),
        _entry('uid-2', 'OldPlayer', 9000, _tenDaysAgo), // older than 7 days
      ]);
    });

    test('excludes entries older than 7 days', () async {
      final data = await service.fetchWeeklyData();

      final names = data.top10.map((e) => e.name).toList();
      expect(names, contains('RecentPlayer'));
      expect(names, isNot(contains('OldPlayer')));
    });

    test('returns correct userRank within weekly scope', () async {
      final data = await service.fetchWeeklyData(uid: 'uid-1');

      expect(data.userRank, isNotNull);
      expect(data.userRank!.$1, 1);
    });
  });

  // fetchUserBestScoreThisWeek() returns the single highest score a specific
  // user achieved in the last 7 days, used to decide whether a new game
  // result should be auto-submitted to the leaderboard.
  group('fetchUserBestScoreThisWeek', () {
    test('returns the highest score within the last 7 days', () async {
      await _seedEntries(db, [
        _entry('uid-alice', 'Alice', 3000, _threeDaysAgo),
        _entry('uid-alice', 'Alice', 1500, _now),
        _entry('uid-alice', 'Alice', 5000, _tenDaysAgo), // outside window
      ]);

      final best = await service.fetchUserBestScoreThisWeek('uid-alice');

      expect(best, 3000);
    });

    test('returns null when user has no entries this week', () async {
      await _seedEntries(db, [
        _entry('uid-alice', 'Alice', 5000, _tenDaysAgo),
      ]);

      final best = await service.fetchUserBestScoreThisWeek('uid-alice');

      expect(best, isNull);
    });

    test('returns null for unknown uid', () async {
      final best = await service.fetchUserBestScoreThisWeek('nobody');

      expect(best, isNull);
    });
  });
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

Map<String, dynamic> _entry(String uid, String name, int score, DateTime date) => {
      'uid': uid,
      'name': name,
      'score': score,
      'lines': 10,
      'level': 2,
      'date': date.toIso8601String(),
      'timestamp': date.millisecondsSinceEpoch,
      'country': '',
    };

Future<void> _seedEntries(FakeFirebaseFirestore db, List<Map<String, dynamic>> entries) async {
  for (final e in entries) {
    await db.collection('leaderboard').add(e);
  }
}
