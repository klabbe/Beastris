import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the auth dialog (Sign In / Register).
class AuthDialogPage {
  final WidgetTester tester;

  AuthDialogPage(this.tester);

  // -- Finders --

  Finder _fieldByHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  Finder get _emailField => _fieldByHint('Email');
  Finder get _passwordField => _fieldByHint('Password');
  Finder get _aliasField => _fieldByHint('Shown on the leaderboard');
  Finder get _nameField =>
      _fieldByHint('Your real name — not shown publicly');

  // -- Actions --

  Future<void> enterEmail(String email) async {
    await tester.enterText(_emailField, email);
    await tester.pump();
  }

  Future<void> enterPassword(String password) async {
    await tester.enterText(_passwordField, password);
    await tester.pump();
  }

  Future<void> enterAlias(String alias) async {
    await tester.enterText(_aliasField, alias);
    await tester.pump();
  }

  Future<void> enterName(String name) async {
    await tester.enterText(_nameField, name);
    await tester.pump();
  }

  /// Toggle to register mode by tapping "Create account".
  Future<void> switchToRegister() async {
    final createAccount = find.text('Create account');
    if (createAccount.evaluate().isNotEmpty) {
      await tester.tap(createAccount);
      await tester.pumpAndSettle();
    }
  }

  /// Toggle to sign-in mode by tapping "Already have an account?".
  Future<void> switchToSignIn() async {
    final alreadyHave = find.text('Already have an account?');
    if (alreadyHave.evaluate().isNotEmpty) {
      await tester.tap(alreadyHave);
      await tester.pumpAndSettle();
    }
  }

  /// Check the privacy policy checkbox.
  Future<void> acceptPrivacyPolicy() async {
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }

  /// Tap the submit button (Register or Sign In).
  Future<void> tapSubmit() async {
    // Find the ElevatedButton in the dialog actions
    final register = find.widgetWithText(ElevatedButton, 'Register');
    final signIn = find.widgetWithText(ElevatedButton, 'Sign In');
    if (register.evaluate().isNotEmpty) {
      await tester.tap(register);
    } else {
      await tester.tap(signIn);
    }
    await tester.pumpAndSettle();
  }

  /// Tap Cancel to close the dialog.
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
