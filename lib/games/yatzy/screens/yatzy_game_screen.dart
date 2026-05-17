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
          _state.players.length > 1
              ? '${player.name}s tur'
              : 'Yatzy',
        ),
        centerTitle: true,
        actions: [
          if (_state.players.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${player.scoreCard.total} p',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Player tabs (multiplayer)
          if (_state.players.length > 1)
            _PlayerTabBar(
              players: _state.players,
              currentIndex: _state.currentPlayerIndex,
            ),

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
                            enabled: canScore == false && _state.rollsLeft < 3,
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

          // Score card
          Expanded(
            child: SingleChildScrollView(
              child: ScoreCardWidget(
                scoreCard: player.scoreCard,
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

class _PlayerTabBar extends StatelessWidget {
  const _PlayerTabBar({
    required this.players,
    required this.currentIndex,
  });

  final List<YatzyPlayer> players;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f0f1e),
      child: Row(
        children: players.asMap().entries.map((e) {
          final isActive = e.key == currentIndex;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    e.value.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withAlpha(120),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${e.value.scoreCard.total}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? const Color(0xFFD1B3FF)
                          : Colors.white.withAlpha(80),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
