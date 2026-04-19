import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the profile dialog (edit profile, sign out, delete account).
class ProfileDialogPage {
  final WidgetTester tester;

  ProfileDialogPage(this.tester);

  // -- Finders --

  Finder _fieldByHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  Finder get _aliasField => _fieldByHint('Shown on the leaderboard');
  Finder get _nameField =>
      _fieldByHint('Your real name — not shown publicly');

  // -- Actions --

  Future<void> clearAndEnterAlias(String alias) async {
    await tester.enterText(_aliasField, alias);
    await tester.pump();
  }

  Future<void> clearAndEnterName(String name) async {
    await tester.enterText(_nameField, name);
    await tester.pump();
  }

  Future<void> tapSave() async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSignOut() async {
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteAccount() async {
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
  }

  /// Confirm the "Delete forever" button on the confirmation dialog.
  Future<void> confirmDelete() async {
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancel() async {
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
  }

  /// Read the error message, if any.
  String? get errorText {
    final errorFinder = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.style?.color == Colors.redAccent &&
          w.data != null &&
          w.data!.isNotEmpty,
    );
    if (errorFinder.evaluate().isEmpty) return null;
    return (errorFinder.evaluate().first.widget as Text).data;
  }
}
