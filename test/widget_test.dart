// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fixit_oman/main.dart';

void main() {
  testWidgets(
      'App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FixitOmanApp());

    // Verify that our app shows the splash screen with correct title
    expect(find.text('Fixit'), findsOneWidget);
    expect(find.text('Your Handyman Solution in Oman'), findsOneWidget);

    // Wait for the timer to complete and navigate to role selection screen
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify we're now on the role selection screen
    expect(find.text('Welcome to Fixit'), findsOneWidget);
    expect(find.text('Choose your role to continue'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Service Provider'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
