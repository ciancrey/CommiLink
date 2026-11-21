import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/service.dart';
import '../screens/my_services_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Side drawer (Figma "05 · Side drawer").
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.onOpenOrders,
  });

  final String userName;
  final VoidCallback onOpenOrders;

  String get _initials => initialsOf(userName);

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Drawer(
      width: 312,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.wine500,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _initials,
                        style: AppText.heading24.copyWith(
                          color: AppColors.textOnBrand,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(userName, style: AppText.heading20),
                    Text(
                      state.profile.value?.roleLabel ?? '',
                      style: AppText.small12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Text(
                'ACCOUNT',
                style: AppText.caption11.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: Listenable.merge(
                  [state.balance, state.orders, state.myServices],
                ),
                builder: (context, _) {
                  final count = state.activeCount;
                  return Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        subtitle: '${formatPeso(state.balance.value)} available',
                        onTap: () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.work_outline_rounded,
                        title: 'My orders',
                        subtitle: '$count active commission'
                            '${count == 1 ? '' : 's'}',
                        onTap: () {
                          Navigator.of(context).pop();
                          onOpenOrders();
                        },
                      ),
                      if (state.profile.value?.isFreelancer == true)
                        _DrawerItem(
                          icon: Icons.storefront_outlined,
                          title: 'My services',
                          subtitle: '${state.myServices.value.length} posted',
                          onTap: () {
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const MyServicesScreen(),
                              ),
                            );
                          },
                        ),
                      _DrawerItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Settings',
                        subtitle: 'Notifications & security',
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop();
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Settings is coming soon.',
                                ),
                              ),
                            );
                        },
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              Material(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await state.signOut();
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(),
                      ),
                          (route) => false,
                    );
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign out',
                          style: AppText.label14.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'CommiLink v1.0 · MockPay top-ups (no real money)',
                  style: AppText.caption11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.peach100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: AppColors.wine700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label14),
                  Text(subtitle, style: AppText.caption11),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}