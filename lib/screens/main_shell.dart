import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Holds the bottom navigation, the side drawer and the main tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        userName: 'Lea Garcia',
        onOpenOrders: () => setState(() => _index = 2),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          _ComingSoon(title: 'Network'),
          OrdersScreen(),
          _ComingSoon(title: 'Messages'),
          _ComingSoon(title: 'Alerts'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: AppBottomNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
}

/// Temporary page for tabs we have not built yet.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title\ncoming soon',
        textAlign: TextAlign.center,
        style: AppText.heading20,
      ),
    );
  }
}