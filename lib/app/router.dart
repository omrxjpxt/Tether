import 'package:flutter/material.dart';
import 'package:tether/features/habits/presentation/screens/today_screen.dart';
import 'package:tether/features/review/presentation/screens/review_screen.dart';
import 'package:tether/features/settings/presentation/screens/settings_screen.dart';
import 'package:tether/shared/widgets/app_scaffold.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    ReviewScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
