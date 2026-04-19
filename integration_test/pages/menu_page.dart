import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the main menu screen.
class MenuPage {
  final WidgetTester tester;

  MenuPage(this.tester);

  /// Whether the user is currently signed in (Sign In button is NOT visible).
  bool get isSignedIn => find.text('Sign In').evaluate().isEmpty;

  /// Whether a specific alias is displayed on screen.
  bool hasAlias(String alias) => find.text(alias).evaluate().isNotEmpty;

  /// Tap the Sign In button (only visible when not signed in).
  Future<void> tapSignIn() async {
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  /// Tap the profile area (account icon + alias, visible when signed in).
  Future<void> tapProfile() async {
    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();
  }

  /// Tap the START GAME button.
  Future<void> tapStartGame() async {
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
  }
}
