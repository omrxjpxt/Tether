import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/screens/today_screen.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';

void main() {
  testWidgets('TodayScreen renders empty state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: TodayScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No habits yet.'), findsOneWidget);
    expect(find.text('Create habit'), findsWidgets);
  });
}
