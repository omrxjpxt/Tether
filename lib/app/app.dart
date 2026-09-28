import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/router.dart';
import 'package:tether/app/theme/app_theme.dart';
import 'package:tether/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tether/features/settings/presentation/providers/settings_provider.dart';

class TetherApp extends ConsumerWidget {
  const TetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Tether',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: settings.isFirstLaunch ? const OnboardingScreen() : const AppNavigationShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
