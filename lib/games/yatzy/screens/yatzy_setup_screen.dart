import 'package:flutter/material.dart';

import 'yatzy_game_screen.dart';

class YatzySetupScreen extends StatefulWidget {
  const YatzySetupScreen({super.key});

  @override
  State<YatzySetupScreen> createState() => _YatzySetupScreenState();
}

class _YatzySetupScreenState extends State<YatzySetupScreen> {
  int _playerCount = 1;
  final List<TextEditingController> _controllers = List.generate(
    4,
    (i) => TextEditingController(text: 'Spelare ${i + 1}'),
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final names = _controllers
        .take(_playerCount)
        .map((c) => c.text.trim().isEmpty ? 'Spelare' : c.text.trim())
        .toList();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => YatzyGameScreen(playerNames: names),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatzy'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Antal spelare',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(4, (i) {
                  final n = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$n'),
                      selected: _playerCount == n,
                      onSelected: (_) => setState(() => _playerCount = n),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                'Spelarnamn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_playerCount, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        labelText: 'Spelare ${i + 1}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF533483),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Starta spel',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
