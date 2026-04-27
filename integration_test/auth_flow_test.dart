import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beastblocks/main.dart';
import 'package:beastblocks/models/user_profile.dart';
import 'package:beastblocks/services/auth_service.dart';

import 'helpers/test_bootstrap.dart';
import 'helpers/test_helpers.dart';
import 'pages/menu_page.dart';
import 'pages/auth_dialog_page.dart';
import 'pages/profile_dialog_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await testBootstrap();
  });

  setUp(() async {
    await resetTestState();
  });

  group('Auth UI Flow —', () {
    testWidgets('register → verify signed in → sign out', (tester) async {
      await tester.pumpWidget(const BeastBlocksApp());
      await tester.pumpAndSettle();

      final menu = MenuPage(tester);
      final authDialog = AuthDialogPage(tester);

      // Not signed in initially
      expect(menu.isSignedIn, isFalse);

      // Open auth dialog
      await menu.tapSignIn();

      // Switch to register mode
      await authDialog.switchToRegister();

      // Fill in registration form
      final email = uniqueEmail('e2e');
      await authDialog.enterEmail(email);
      await authDialog.enterPassword('password123');
      await authDialog.enterAlias('E2EPlayer');
      await authDialog.acceptPrivacyPolicy();

      // Submit registration
      await authDialog.tapSubmit();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should be signed in now, alias visible
      expect(menu.isSignedIn, isTrue);
      expect(menu.hasAlias('E2EPlayer'), isTrue);

      // Open profile dialog and sign out
      await menu.tapProfile();
      final profileDialog = ProfileDialogPage(tester);
      await profileDialog.tapSignOut();
      await tester.pumpAndSettle();

      // Should be back to signed-out state
      expect(menu.isSignedIn, isFalse);
    });

    testWidgets('sign in with existing account', (tester) async {
      // Pre-register a user via the service
      final email = uniqueEmail('e2e_existing');
      final preAuth = AuthService();
      await preAuth.register(
        email,
        'password123',
        UserProfile(uid: '', alias: 'ExistingUser'),
      );
      // Wait for profile write to complete
      await Future<void>.delayed(const Duration(seconds: 2));
      await preAuth.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Now launch the app and sign in through UI
      await tester.pumpWidget(const BeastBlocksApp());
      await tester.pumpAndSettle();

      final menu = MenuPage(tester);
      final authDialog = AuthDialogPage(tester);

      await menu.tapSignIn();
      await authDialog.enterEmail(email);
      await authDialog.enterPassword('password123');
      await authDialog.tapSubmit();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(menu.isSignedIn, isTrue);
      expect(menu.hasAlias('ExistingUser'), isTrue);

      // Clean up
      await menu.tapProfile();
      final profileDialog = ProfileDialogPage(tester);
      await profileDialog.tapSignOut();
      await tester.pumpAndSettle();
    });

    testWidgets('update profile through UI', (tester) async {
      // Pre-register
      final email = uniqueEmail('e2e_profile');
      final preAuth = AuthService();
      await preAuth.register(
        email,
        'password123',
        UserProfile(uid: '', alias: 'OriginalAlias'),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await preAuth.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Launch app and sign in
      await tester.pumpWidget(const BeastBlocksApp());
      await tester.pumpAndSettle();

      final menu = MenuPage(tester);
      final authDialog = AuthDialogPage(tester);

      await menu.tapSignIn();
      await authDialog.enterEmail(email);
      await authDialog.enterPassword('password123');
      await authDialog.tapSubmit();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open profile dialog and change alias
      await menu.tapProfile();
      final profileDialog = ProfileDialogPage(tester);
      await profileDialog.clearAndEnterAlias('UpdatedAlias');
      await profileDialog.tapSave();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify updated alias is shown on menu
      expect(menu.hasAlias('UpdatedAlias'), isTrue);

      // Clean up
      await menu.tapProfile();
      await profileDialog.tapSignOut();
      await tester.pumpAndSettle();
    });

    testWidgets('delete account through UI', (tester) async {
      // Pre-register
      final email = uniqueEmail('e2e_delete');
      final preAuth = AuthService();
      await preAuth.register(
        email,
        'password123',
        UserProfile(uid: '', alias: 'DeleteMe'),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await preAuth.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Launch app and sign in
      await tester.pumpWidget(const BeastBlocksApp());
      await tester.pumpAndSettle();

      final menu = MenuPage(tester);
      final authDialog = AuthDialogPage(tester);

      await menu.tapSignIn();
      await authDialog.enterEmail(email);
      await authDialog.enterPassword('password123');
      await authDialog.tapSubmit();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(menu.isSignedIn, isTrue);

      // Open profile → delete account
      await menu.tapProfile();
      final profileDialog = ProfileDialogPage(tester);
      await profileDialog.tapDeleteAccount();
      await profileDialog.confirmDelete();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should be signed out after deletion
      expect(menu.isSignedIn, isFalse);
    });
  });
}
