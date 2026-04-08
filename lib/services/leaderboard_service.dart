import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_history.dart';

class LeaderboardService {
  static const _collection = 'leaderboard';
  static const int maxEntries = 10;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a score. Only saves if it's in the top [maxEntries].
  Future<void> submitScore(GameResult result, String playerName) async {
    try {
      await _db.collection(_collection).add({
        'name': playerName,
        'score': result.score,
        'lines': result.lines,
        'level': result.level,
        'date': result.date.toIso8601String(),
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
          .limit(maxEntries)
          .get();
      debugPrint('Leaderboard: fetched ${snapshot.docs.length} entries');
      return snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Leaderboard read ERROR: $e');
      rethrow;
    }
  }

  /// Stream of top scores for real-time updates.
  Stream<List<LeaderboardEntry>> topScoresStream() {
    return _db
        .collection(_collection)
        .orderBy('score', descending: true)
        .limit(maxEntries)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LeaderboardEntry.fromMap(d.data())).toList());
  }
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int lines;
  final int level;
  final String date;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.lines,
    required this.level,
    required this.date,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
        name: map['name'] as String? ?? 'Unknown',
        score: map['score'] as int? ?? 0,
        lines: map['lines'] as int? ?? 0,
        level: map['level'] as int? ?? 1,
        date: map['date'] as String? ?? '',
      );
}
