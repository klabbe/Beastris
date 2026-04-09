import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_history.dart';

class LeaderboardService {
  static const _collection = 'leaderboard';
  static const int maxEntries = 10;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitScore(GameResult result, String playerName,
      {String? uid, String? country}) async {
    try {
      await _db.collection(_collection).add({
        'name': playerName,
        'score': result.score,
        'lines': result.lines,
        'level': result.level,
        'date': result.date.toIso8601String(),
        'timestamp': result.date.millisecondsSinceEpoch,
        if (uid != null) 'uid': uid,
        if (country != null && country.isNotEmpty) 'country': country,
      });
      debugPrint('Leaderboard: score submitted for $playerName (${result.score})');
    } catch (e) {
      debugPrint('Leaderboard write ERROR: $e');
      rethrow;
    }
  }

  Future<List<LeaderboardEntry>> fetchTopScores() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('score', descending: true)
          .limit(100)
          .get();
      debugPrint('Leaderboard: fetched ${snapshot.docs.length} entries');
      return snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data()))
          .take(maxEntries)
          .toList();
    } catch (e) {
      debugPrint('Leaderboard read ERROR: $e');
      rethrow;
    }
  }

  Future<List<LeaderboardEntry>> fetchWeeklyScores() async {
    try {
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final snapshot = await _db
          .collection(_collection)
          .orderBy('score', descending: true)
          .limit(100)
          .get();
      final entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data()))
          .where((e) => e.timestamp >= weekAgo)
          .take(maxEntries)
          .toList();
      debugPrint('Leaderboard weekly: ${entries.length} entries');
      return entries;
    } catch (e) {
      debugPrint('Leaderboard weekly ERROR: $e');
      rethrow;
    }
  }
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int lines;
  final int level;
  final String date;
  final int timestamp;
  final String country;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.lines,
    required this.level,
    required this.date,
    this.timestamp = 0,
    this.country = '',
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
        name: map['name'] as String? ?? 'Unknown',
        score: map['score'] as int? ?? 0,
        lines: map['lines'] as int? ?? 0,
        level: map['level'] as int? ?? 1,
        date: map['date'] as String? ?? '',
        timestamp: map['timestamp'] as int? ?? 0,
        country: map['country'] as String? ?? '',
      );
}
