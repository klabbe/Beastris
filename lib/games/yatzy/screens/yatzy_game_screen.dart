import 'package:flutter/material.dart';

import '../engine.dart';
import '../models/score_card.dart';
import '../widgets/die_widget.dart';
import '../widgets/score_card_widget.dart';

class YatzyGameScreen extends StatefulWidget {
  const YatzyGameScreen({super.key, required this.playerNames});

  final List<String> playerNames;

  @override
  State<YatzyGameScreen> createState() => _YatzyGameScreenState();
}

class _YatzyGameScreenState extends State<YatzyGameScreen> {
  final _engine = YatzyEngine();
  late YatzyGameState _state;

  @override
  void initState() {
    super.initState();
    _state = _engine.newGame(playerNames: widget.playerNames);
  }

  void _roll() {
    setState(() => _state = _engine.roll(_state));
  }

  void _toggleHold(int index) {
    setState(() => _state = _engine.toggleHold(_state, index));
  }

  void _scoreCategory(ScoreCategory cat) {
    setState(() => _state = _engine.score(_state, cat));
    if (_state.isGameOver) _showGameOver();
  }

  void _showGameOver() {
    final sorted = List.of(_state.players)
      ..sort((a, b) => b.scoreCard.total.compareTo(a.scoreCard.total));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Spelet är slut!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Slutresultat:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sorted.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '${e.key + 1}. ${e.value.name}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value.scoreCard.total} p',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // back to portal
            },
            child: const Text('Avsluta'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _state = _engine.newGame(playerNames: widget.playerNames);
              });
            },
            child: const Text('Spela igen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = _state.currentPlayer;
    final previews =
        _state.rollsLeft < 3 ? _engine.previews(_state) : <ScoreCategory, int>{};
    final canScore = _state.rollsLeft < 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _state.players.length > 1 ? '${player.name}s tur' : 'Yatzy',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Dice area
          Container(
            color: const Color(0xFF1a1a2e),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _state.dice
                      .asMap()
                      .entries
                      .map((e) => DieWidget(
                            die: e.value,
                            onTap: () => _toggleHold(e.key),
                            enabled: _state.rollsLeft > 0 && _state.rollsLeft < 3,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _state.rollsLeft > 0 &&
                              _state.phase == TurnPhase.rolling
                          ? _roll
                          : null,
                      icon: const Icon(Icons.casino_rounded),
                      label: Text(_state.rollsLeft == 3
                          ? 'Kasta'
                          : 'Kasta om (${_state.rollsLeft} kvar)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF533483),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (canScore)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Välj en kategori nedan att poängsätta',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(150)),
                    ),
                  ),
              ],
            ),
          ),

          // Score card – multi-column
          Expanded(
            child: SingleChildScrollView(
              child: ScoreCardWidget(
                players: _state.players,
                currentPlayerIndex: _state.currentPlayerIndex,
                previews: previews,
                onSelectCategory: _scoreCategory,
                canScore: canScore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
