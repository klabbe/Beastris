import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GameResult {
  final int score;
  final int lines;
  final int level;
  final DateTime date;

  GameResult({
    required this.score,
    required this.lines,
    required this.level,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'lines': lines,
        'level': level,
        'date': date.toIso8601String(),
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        score: json['score'] as int,
        lines: json['lines'] as int,
        level: json['level'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class GameHistory {
  static const _key = 'game_history';
  static const int maxRecent = 5;
  static const int maxTopScores = 3;

  List<GameResult> _results = [];

  List<GameResult> get recentGames {
    final sorted = List<GameResult>.from(_results)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(maxRecent).toList();
  }

  List<GameResult> get topScores {
    final sorted = List<GameResult>.from(_results)
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(maxTopScores).toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _results = list
          .map((e) => GameResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> addResult(GameResult result) async {
    _results.add(result);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_results.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }
}
