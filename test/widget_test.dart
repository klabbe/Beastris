import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart'
    show setupFirebaseCoreMocks;
import 'package:flutter_test/flutter_test.dart';

import 'package:beastblocks/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const BeastBlocksApp());
    expect(find.text('🐾 BEASTBLOCKS 🐾'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });
}
