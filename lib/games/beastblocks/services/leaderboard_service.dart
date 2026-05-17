import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_history.dart';

class LeaderboardService {
  static const _collection = 'leaderboard';
  static const int maxEntries = 10;

  final FirebaseFirestore _db;

  LeaderboardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

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

  Future<({List<LeaderboardEntry> top10, (int, LeaderboardEntry)? userRank})>
      fetchAllTimeData({String? uid}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('score', descending: true)
          .limit(200)
          .get();
      final all = snapshot.docs
          .map((d) => LeaderboardEntry.fromMap(d.data()))
          .toList();
      // Deduplicate: keep only the best score per uid (anonymous entries stay)
      final deduped = _deduplicateByUid(all);
      final top10 = deduped.take(maxEntries).toList();
      (int, LeaderboardEntry)? userRank;
      if (uid != null) {
        final idx = deduped.indexWhere((e) => e.uid == uid);
        if (idx >= 0) userRank = (idx + 1, deduped[idx]);
      }
      debugPrint('Leaderboard: fetched ${all.length} entries (${deduped.length} unique players)');
      return (top10: top10, userRank: userRank);
    } catch (e) {
      debugPrint('Leaderboard read ERROR: $e');
      rethrow;
    }
  }

  Future<({List<LeaderboardEntry> top10, (int, LeaderboardEntry)? userRank})>
      fetchWeeklyData({String? uid}) async {
    try {
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final snapshot = await _db
          .collection(_collection)
          .orderBy('score', descending: true)
          .limit(200)
          .get();
      final weekly = snapshot.docs
          .map((d) => LeaderboardEntry.fromMap(d.data()))
          .where((e) => e.timestamp >= weekAgo)
          .toList();
      // Deduplicate: keep only the best score per uid (anonymous entries stay)
      final deduped = _deduplicateByUid(weekly);
      final top10 = deduped.take(maxEntries).toList();
      (int, LeaderboardEntry)? userRank;
      if (uid != null) {
        final idx = deduped.indexWhere((e) => e.uid == uid);
        if (idx >= 0) userRank = (idx + 1, deduped[idx]);
      }
      debugPrint('Leaderboard weekly: ${top10.length} entries');
      return (top10: top10, userRank: userRank);
    } catch (e) {
      debugPrint('Leaderboard weekly ERROR: $e');
      rethrow;
    }
  }

  /// Best score the user has this week, or null if none.
  Future<int?> fetchUserBestScoreThisWeek(String uid) async {
    try {
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final snapshot = await _db
          .collection(_collection)
          .where('uid', isEqualTo: uid)
          .get();
      final scores = snapshot.docs
          .map((d) => LeaderboardEntry.fromMap(d.data()))
          .where((e) => e.timestamp >= weekAgo)
          .map((e) => e.score)
          .toList();
      if (scores.isEmpty) return null;
      scores.sort((a, b) => b.compareTo(a));
      return scores.first;
    } catch (e) {
      debugPrint('Leaderboard: fetchUserBestScoreThisWeek error: $e');
      return null;
    }
  }

  /// Keep only the best (first) entry per uid. Entries with empty uid are always kept.
  static List<LeaderboardEntry> _deduplicateByUid(List<LeaderboardEntry> sorted) {
    final seen = <String>{};
    final result = <LeaderboardEntry>[];
    for (final e in sorted) {
      if (e.uid.isEmpty || seen.add(e.uid)) {
        result.add(e);
      }
    }
    return result;
  }
}

class LeaderboardEntry {
  final String uid;
  final String name;
  final int score;
  final int lines;
  final int level;
  final String date;
  final int timestamp;
  final String country;

  LeaderboardEntry({
    this.uid = '',
    required this.name,
    required this.score,
    required this.lines,
    required this.level,
    required this.date,
    this.timestamp = 0,
    this.country = '',
  });

  /// Returns the name to display publicly. Entries with an empty uid have
  /// been anonymised (account deleted) and show a placeholder instead.
  String get displayName => uid.isEmpty ? 'Erased alias' : name;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? 'Unknown',
        score: map['score'] as int? ?? 0,
        lines: map['lines'] as int? ?? 0,
        level: map['level'] as int? ?? 1,
        date: map['date'] as String? ?? '',
        timestamp: map['timestamp'] as int? ?? 0,
        country: map['country'] as String? ?? '',
      );
}
