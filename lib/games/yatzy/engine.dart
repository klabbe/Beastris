import 'dart:math';

import 'models/die.dart';
import 'models/score_card.dart';

enum GameMode { singlePlayer, passAndPlay, online }

enum TurnPhase { rolling, scoring }

class YatzyPlayer {
  final String id;
  final String name;
  final ScoreCard scoreCard;

  const YatzyPlayer({
    required this.id,
    required this.name,
    required this.scoreCard,
  });

  YatzyPlayer copyWith({String? name, ScoreCard? scoreCard}) {
    return YatzyPlayer(
      id: id,
      name: name ?? this.name,
      scoreCard: scoreCard ?? this.scoreCard,
    );
  }
}

class YatzyGameState {
  final List<YatzyPlayer> players;
  final int currentPlayerIndex;
  final List<Die> dice;
  final int rollsLeft;
  final TurnPhase phase;
  final bool isGameOver;

  const YatzyGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.dice,
    required this.rollsLeft,
    required this.phase,
    this.isGameOver = false,
  });

  YatzyPlayer get currentPlayer => players[currentPlayerIndex];

  List<int> get diceValues => dice.map((d) => d.value).toList();

  YatzyGameState copyWith({
    List<YatzyPlayer>? players,
    int? currentPlayerIndex,
    List<Die>? dice,
    int? rollsLeft,
    TurnPhase? phase,
    bool? isGameOver,
  }) {
    return YatzyGameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      dice: dice ?? this.dice,
      rollsLeft: rollsLeft ?? this.rollsLeft,
      phase: phase ?? this.phase,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }
}

class YatzyEngine {
  final _rng = Random();

  YatzyGameState newGame({
    required List<String> playerNames,
    GameMode mode = GameMode.singlePlayer,
  }) {
    assert(playerNames.isNotEmpty);
    final players = playerNames
        .asMap()
        .entries
        .map((e) => YatzyPlayer(
              id: 'p${e.key}',
              name: e.value,
              scoreCard: ScoreCard.empty(),
            ))
        .toList();

    return YatzyGameState(
      players: players,
      currentPlayerIndex: 0,
      dice: List.generate(5, (_) => const Die(value: 1)),
      rollsLeft: 3,
      phase: TurnPhase.rolling,
    );
  }

  /// Roll all non-held dice.
  YatzyGameState roll(YatzyGameState state) {
    if (state.rollsLeft <= 0 || state.phase != TurnPhase.rolling) return state;
    final newDice = state.dice.map((d) => d.rolled(_rng)).toList();
    final newRolls = state.rollsLeft - 1;
    return state.copyWith(
      dice: newDice,
      rollsLeft: newRolls,
      phase: newRolls == 0 ? TurnPhase.scoring : TurnPhase.rolling,
    );
  }

  /// Toggle held state of a die by index.
  YatzyGameState toggleHold(YatzyGameState state, int index) {
    if (state.phase != TurnPhase.rolling || state.rollsLeft == 3) return state;
    final newDice = List<Die>.from(state.dice);
    newDice[index] = newDice[index].copyWith(held: !newDice[index].held);
    return state.copyWith(dice: newDice);
  }

  /// Score the current dice in the given category for the current player.
  YatzyGameState score(YatzyGameState state, ScoreCategory cat) {
    final player = state.currentPlayer;
    if (player.scoreCard.isScored(cat)) return state;
    if (state.rollsLeft == 3) return state; // must roll at least once

    final value = ScoreCard.calculate(cat, state.diceValues);
    final updatedCard = player.scoreCard.withScore(cat, value);
    final updatedPlayer = player.copyWith(scoreCard: updatedCard);
    final updatedPlayers = List<YatzyPlayer>.from(state.players);
    updatedPlayers[state.currentPlayerIndex] = updatedPlayer;

    // Advance to next player or end game
    final nextIndex =
        (state.currentPlayerIndex + 1) % updatedPlayers.length;
    final isGameOver = updatedPlayers.every((p) => p.scoreCard.isComplete);

    return state.copyWith(
      players: updatedPlayers,
      currentPlayerIndex: nextIndex,
      dice: List.generate(5, (_) => const Die(value: 1)),
      rollsLeft: 3,
      phase: TurnPhase.rolling,
      isGameOver: isGameOver,
    );
  }

  /// Preview score for each unscored category with current dice.
  Map<ScoreCategory, int> previews(YatzyGameState state) {
    final diceValues = state.diceValues;
    return {
      for (final cat in ScoreCategory.values)
        if (!state.currentPlayer.scoreCard.isScored(cat))
          cat: ScoreCard.calculate(cat, diceValues),
    };
  }
}
