import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chpa/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches and shows Login Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The login screen should be visible
      expect(find.text('CHPA'), findsWidgets);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Login screen has Email and Password fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find email and password fields
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('Tapping Sign Up navigates to signup screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap the Sign Up text button
      final signUpFinder = find.text('Sign Up');
      expect(signUpFinder, findsOneWidget);
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on signup screen
      expect(find.text('Create Account'), findsAny);
    });

    testWidgets('Empty login form shows validation errors', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap Sign In button without filling fields
      final signInFinder = find.text('Sign In');
      expect(signInFinder, findsOneWidget);
      await tester.tap(signInFinder);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('Forgot Password navigates to forgot password screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Forgot Password
      final forgotFinder = find.text('Forgot Password?');
      expect(forgotFinder, findsOneWidget);
      await tester.tap(forgotFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on forgot password screen
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
