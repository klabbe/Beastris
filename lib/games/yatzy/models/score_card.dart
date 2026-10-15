enum ScoreCategory {
  ones,
  twos,
  threes,
  fours,
  fives,
  sixes,
  onePair,
  twoPairs,
  threeOfAKind,
  fourOfAKind,
  smallStraight,
  largeStraight,
  fullHouse,
  chance,
  yatzy,
}

extension ScoreCategoryName on ScoreCategory {
  String get displayName => switch (this) {
        ScoreCategory.ones => 'Ettor',
        ScoreCategory.twos => 'Tvåor',
        ScoreCategory.threes => 'Treor',
        ScoreCategory.fours => 'Fyror',
        ScoreCategory.fives => 'Femmor',
        ScoreCategory.sixes => 'Sexor',
        ScoreCategory.onePair => 'Ett par',
        ScoreCategory.twoPairs => 'Två par',
        ScoreCategory.threeOfAKind => 'Tretal',
        ScoreCategory.fourOfAKind => 'Fyrtal',
        ScoreCategory.smallStraight => 'Liten stege',
        ScoreCategory.largeStraight => 'Stor stege',
        ScoreCategory.fullHouse => 'Kåk',
        ScoreCategory.chance => 'Chansen',
        ScoreCategory.yatzy => 'Yatzy',
      };

  bool get isUpperSection => index <= ScoreCategory.sixes.index;
}

/// Immutable score sheet for one player. Null = not yet scored.
class ScoreCard {
  final Map<ScoreCategory, int?> _scores;

  const ScoreCard._(this._scores);

  factory ScoreCard.empty() => ScoreCard._(
        {for (final c in ScoreCategory.values) c: null},
      );

  int? operator [](ScoreCategory cat) => _scores[cat];

  bool isScored(ScoreCategory cat) => _scores[cat] != null;

  bool get isComplete => _scores.values.every((v) => v != null);

  ScoreCard withScore(ScoreCategory cat, int value) {
    assert(!isScored(cat), 'Category $cat already scored');
    return ScoreCard._(Map.of(_scores)..[cat] = value);
  }

  int get upperSum {
    int sum = 0;
    for (final cat in ScoreCategory.values.where((c) => c.isUpperSection)) {
      sum += _scores[cat] ?? 0;
    }
    return sum;
  }

  int get upperBonus => upperSum >= 63 ? 50 : 0;

  int get lowerSum {
    int sum = 0;
    for (final cat in ScoreCategory.values.where((c) => !c.isUpperSection)) {
      sum += _scores[cat] ?? 0;
    }
    return sum;
  }

  int get total => upperSum + upperBonus + lowerSum;

  /// Calculate the score a set of dice would yield for a given category.
  static int calculate(ScoreCategory cat, List<int> dice) {
    assert(dice.length == 5);
    final counts = <int, int>{};
    for (final d in dice) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final sorted = List<int>.from(dice)..sort();

    return switch (cat) {
      ScoreCategory.ones => dice.where((d) => d == 1).fold(0, (s, d) => s + d),
      ScoreCategory.twos => dice.where((d) => d == 2).fold(0, (s, d) => s + d),
      ScoreCategory.threes =>
        dice.where((d) => d == 3).fold(0, (s, d) => s + d),
      ScoreCategory.fours =>
        dice.where((d) => d == 4).fold(0, (s, d) => s + d),
      ScoreCategory.fives =>
        dice.where((d) => d == 5).fold(0, (s, d) => s + d),
      ScoreCategory.sixes =>
        dice.where((d) => d == 6).fold(0, (s, d) => s + d),
      ScoreCategory.onePair => _bestOfKind(counts, 2) * 2,
      ScoreCategory.twoPairs => _twoPairs(counts),
      ScoreCategory.threeOfAKind => _bestOfKind(counts, 3) * 3,
      ScoreCategory.fourOfAKind => _bestOfKind(counts, 4) * 4,
      ScoreCategory.smallStraight =>
        sorted.join() == '12345' ? 15 : 0,
      ScoreCategory.largeStraight =>
        sorted.join() == '23456' ? 20 : 0,
      ScoreCategory.fullHouse => _fullHouse(counts),
      ScoreCategory.chance => dice.fold(0, (s, d) => s + d),
      ScoreCategory.yatzy =>
        counts.values.any((c) => c == 5) ? 50 : 0,
    };
  }

  static int _bestOfKind(Map<int, int> counts, int n) {
    int best = 0;
    for (final entry in counts.entries) {
      if (entry.value >= n && entry.key > best) {
        best = entry.key;
      }
    }
    return best;
  }

  static int _twoPairs(Map<int, int> counts) {
    final pairs = counts.entries.where((e) => e.value >= 2).map((e) => e.key).toList()
      ..sort();
    if (pairs.length < 2) return 0;
    return (pairs[pairs.length - 1] + pairs[pairs.length - 2]) * 2;
  }

  static int _fullHouse(Map<int, int> counts) {
    final values = counts.values.toList()..sort();
    if (values.length == 2 && values[0] == 2 && values[1] == 3) {
      return counts.keys.fold(0, (s, k) => s + k * counts[k]!);
    }
    return 0;
  }
}
