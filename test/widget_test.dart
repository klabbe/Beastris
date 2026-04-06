import 'package:flutter_test/flutter_test.dart';

import 'package:beastris/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const BeastrisApp());
    expect(find.text('🐾 BEASTRIS 🐾'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });
}
