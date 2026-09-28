import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tether/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OnboardingScreen renders Tether brand and starter templates', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tether'), findsOneWidget);
    expect(find.text('Build habits that stick.'), findsOneWidget);
    expect(find.text('"Connect a small action to something you already do."'), findsOneWidget);
    expect(find.text('START WITH A TEMPLATE'), findsOneWidget);
    expect(find.text('Create custom habit'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Verify templates are present
    expect(find.text('After I sit at my desk'), findsOneWidget);
    expect(find.text('After I finish brushing my teeth'), findsOneWidget);
    expect(find.text('After I close my laptop'), findsOneWidget);
  });

  testWidgets('Tapping Skip completes onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(container.read(appSettingsProvider).isFirstLaunch, true);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(container.read(appSettingsProvider).isFirstLaunch, false);
    expect(prefs.getString('app_settings_v1'), contains('"isFirstLaunch":false'));
  });

  testWidgets('Tapping a template adds the habit and completes onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(habitsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('After I sit at my desk'));
    await tester.pumpAndSettle();

    expect(container.read(appSettingsProvider).isFirstLaunch, false);

    final habits = container.read(habitsProvider).value ?? [];
    expect(habits.length, 1);
    expect(habits.first.trigger, 'sit at my desk');
    expect(habits.first.action, 'write my top priority for the next hour');
  });
}
