import 'package:flutter/material.dart';
import 'package:tether/features/habits/presentation/screens/today_screen.dart';
import 'package:tether/features/review/presentation/screens/review_screen.dart';
import 'package:tether/shared/widgets/app_scaffold.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/app/theme/app_spacing.dart';

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
    _SettingsPlaceholder(),
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

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings', style: AppTypography.headingSection),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Tether preferences will appear here.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
