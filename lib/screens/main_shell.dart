import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../data/social_state.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'network_screen.dart';
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
      drawer: ValueListenableBuilder(
        valueListenable: AppState.instance.profile,
        builder: (context, profile, _) => AppDrawer(
          userName: profile?.fullName ?? '',
          onOpenOrders: () => setState(() => _index = 2),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          NetworkScreen(),
          OrdersScreen(),
          MessagesScreen(),
          AlertsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              SocialState.instance.alerts,
              SocialState.instance.conversations,
            ]),
            builder: (context, _) => AppBottomNav(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              messagesDot: SocialState.instance.unreadMessages > 0,
              alertsDot: SocialState.instance.unreadAlerts > 0,
            ),
          ),
        ),
      ),
    );
  }
}
