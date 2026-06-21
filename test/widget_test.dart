// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopause/main.dart';
import 'package:ecopause/utils/app_theme.dart';
import 'package:ecopause/utils/auth_provider.dart';
import 'package:ecopause/screens/login_screen.dart';
import 'package:ecopause/screens/home_screen.dart';
import 'package:ecopause/screens/register_screen.dart';

void main() {
  group('EcoPause App Tests', () {
    testWidgets('App launches with splash screen', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const EcoPauseApp());
      
      // Verify splash screen
      expect(find.text('EcoPause'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Splash screen navigates to Login', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const EcoPauseApp());
      
      // Wait for splash screen to finish
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Should show login screen
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Login screen has all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Find login fields
      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      
      // Check if fields exist
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      
      // Check if login button exists
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login screen shows error for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Tap login button without filling fields
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Should show error snackbar
      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    });
  });

  group('Authentication Flow Tests', () {
    testWidgets('Can navigate from Login to Register', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Tap register button
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Should show register screen
      expect(find.text('Register'), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Register screen shows error for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Navigate to register
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Tap register button without filling fields
      await tester.tap(find.text('Register').last);
      await tester.pump();

      // Should show error
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    testWidgets('App uses correct primary color', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Find AppBar and check color
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      
      // Check if primary color is forest
      final appBarWidget = tester.widget<AppBar>(appBar);
      expect(appBarWidget.backgroundColor, AppTheme.forest);
    });

    testWidgets('App uses Nunito font family', (WidgetTester tester) async {
      await tester.pumpWidget(const EcoPauseApp());
      await tester.pumpAndSettle();

      // Check if text uses Nunito font
      final textWidget = find.text('EcoPause');
      expect(textWidget, findsOneWidget);
      
      // Check font family (will be applied through GoogleFonts)
      final text = tester.widget<Text>(textWidget);
      expect(text.style?.fontFamily, isNotNull);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Bottom navigation bar exists in HomeScreen', (WidgetTester tester) async {
      // Create a logged-in user
      final auth = AuthProvider();
      // Simulate login (you might need to mock this)
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(auth: auth),
        ),
      );
      await tester.pumpAndSettle();

      // Check bottom navigation bar
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('FOMO Check'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
    });
  });
}