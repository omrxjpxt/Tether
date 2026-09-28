import 'package:flutter/material.dart';
import 'package:tether/shared/widgets/app_scaffold.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Today (Phase 2)')),
    Center(child: Text('Review (Phase 3)')),
    Center(child: Text('Settings (Phase 4)')),
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
