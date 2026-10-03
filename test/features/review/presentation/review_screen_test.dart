import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/review/presentation/screens/review_screen.dart';

void main() {
  testWidgets('ReviewScreen shows appropriate empty state copy for current week', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ReviewScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Weekly Review'), findsOneWidget);
    expect(find.text('Your week is just getting started.'), findsOneWidget);
  });

  testWidgets('ReviewScreen shows future week copy when navigating to future week', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ReviewScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Tap next week navigation button
    await tester.tap(find.byTooltip('Next week'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Weekly Review'), findsOneWidget);
    expect(find.text("This week hasn't started yet."), findsOneWidget);
  });
}
