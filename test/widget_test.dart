import 'package:flutter_test/flutter_test.dart';

import 'package:beastris/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const BeastBlocksApp());
    expect(find.text('🐾 BEASTBLOCKS 🐾'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });
}
