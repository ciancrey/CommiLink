import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';
import 'wallet_screen.dart';

/// NEW PAGE · 24 · Alerts (Figma node 11:1391)
/// Data: `notifications` table, written automatically by the database
/// whenever an order changes or the wallet is topped up.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static IconData _icon(String kind) {
    switch (kind) {
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'delivered':
        return Icons.upload_rounded;
      case 'held':
        return Icons.lock_outline_rounded;
      case 'topup':
        return Icons.account_balance_wallet_outlined;
      case 'dispute':
        return Icons.gavel_rounded;
      case 'refund':
        return Icons.replay_rounded;
      case 'released':
        return Icons.payments_outlined;
      case 'request':
        return Icons.work_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(BuildContext context, AppAlert alert) async {
    final social = SocialState.instance;
    social.markAlertRead(alert).catchError((Object _) {});
    if (alert.orderId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: alert.orderId!),
        ),
      );
    } else if (alert.kind == 'topup') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WalletScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = SocialState.instance;

    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<List<AppAlert>>(
        valueListenable: social.alerts,
        builder: (context, alerts, _) {
          final now = DateTime.now();
          bool isToday(DateTime d) =>
              d.year == now.year && d.month == now.month && d.day == now.day;
          final today = alerts.where((a) => isToday(a.createdAt)).toList();
          final earlier = alerts.where((a) => !isToday(a.createdAt)).toList();

          return RefreshIndicator(
            color: AppColors.wine700,
            onRefresh: () async {
              try {
                await social.refresh();
              } on AppException catch (e) {
                if (context.mounted) _toast(context, e.message);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Alerts', style: AppText.heading24)),
                    if (social.unreadAlerts > 0)
                      TextButton(
                        onPressed: () async {
                          try {
                            await social.markAllAlertsRead();
                          } on AppException catch (e) {
                            if (context.mounted) _toast(context, e.message);
                          }
                        },
                        child: Text(
                          'Mark all as read',
                          style: AppText.small12Medium
                              .copyWith(color: AppColors.wine700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            size: 36, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No alerts yet', style: AppText.title16),
                        const SizedBox(height: 4),
                        Text(
                          'Updates about your commissions and wallet '
                          'will show up here.',
                          textAlign: TextAlign.center,
                          style: AppText.small12,
                        ),
                      ],
                    ),
                  ),
                if (today.isNotEmpty) ...[
                  _section('TODAY'),
                  for (final a in today)
                    _AlertCard(
                      alert: a,
                      icon: _icon(a.kind),
                      onTap: () => _open(context, a),
                    ),
                ],
                if (earlier.isNotEmpty) ...[
                  _section('EARLIER'),
                  for (final a in earlier)
                    _AlertCard(
                      alert: a,
                      icon: _icon(a.kind),
                      onTap: () => _open(context, a),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Text(
          label,
          style: AppText.caption11.copyWith(letterSpacing: 1),
        ),
      );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.icon,
    required this.onTap,
  });

  final AppAlert alert;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = alert.isUnread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unread ? AppColors.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: unread
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.peach100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: AppColors.wine700),
                    ),
                    if (unread)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.wine700,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(alert.title, style: AppText.label14),
                          ),
                          const SizedBox(width: 8),
                          Text(agoTime(alert.createdAt),
                              style: AppText.caption11),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.body,
                        style: AppText.small12
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
