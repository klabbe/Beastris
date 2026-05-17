import 'dart:math';

class Die {
  final int value;
  final bool held;

  const Die({required this.value, this.held = false});

  Die copyWith({int? value, bool? held}) {
    return Die(value: value ?? this.value, held: held ?? this.held);
  }

  Die rolled(Random rng) {
    if (held) return this;
    return Die(value: rng.nextInt(6) + 1, held: false);
  }
}
