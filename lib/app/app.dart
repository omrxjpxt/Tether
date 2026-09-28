import 'package:flutter/material.dart';
import 'package:tether/app/theme/app_theme.dart';
import 'package:tether/app/router.dart';

class TetherApp extends StatelessWidget {
  const TetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tether',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppNavigationShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
