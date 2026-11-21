import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/status_badge.dart';
import 'order_detail_screen.dart';

/// Page 13 · Orders (Figma node 9:604)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const List<String> _filters = [
    'All',
    'Active',
    'Completed',
    'Disputed',
  ];

  final _state = AppState.instance;
  String _filter = 'All';

  List<Order> _visible(List<Order> all) {
    switch (_filter) {
      case 'Active':
        return all.where((o) => o.isActive).toList();
      case 'Completed':
        return all.where((o) => o.status == 'Completed').toList();
      case 'Disputed':
        return all
            .where((o) => o.status == 'Disputed' || o.disputeNumber != null)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<List<Order>>(
        valueListenable: _state.orders,
        builder: (context, orders, _) {
          final visible = _visible(orders);
          final me = _state.profile.value;

          return RefreshIndicator(
            color: AppColors.wine700,
            onRefresh: () async {
              try {
                await _state.refresh();
              } on AppException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orders', style: AppText.heading24),
                const SizedBox(height: 2),
                Text(
                  me?.isAdmin == true
                      ? 'All commissions · resolve disputes here'
                      : me?.isFreelancer == true
                          ? 'Requests from your clients'
                          : 'Track every commission you\u2019ve placed',
                  style: AppText.small12,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _filters) ...[
                        _FilterChip(
                          label: f,
                          selected: f == _filter,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  _buildEmpty(orders.isEmpty)
                else
                  for (final order in visible) ...[
                    _OrderCard(
                      order: order,
                      viewerId: me?.id,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(bool noOrdersAtAll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.work_outline_rounded,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            noOrdersAtAll ? 'No orders yet' : 'Nothing here',
            style: AppText.title16,
          ),
          const SizedBox(height: 4),
          Text(
            noOrdersAtAll
                ? (_state.profile.value?.isFreelancer == true
                    ? 'When a client requests one of your services it will show up here.'
                    : 'Request a service from Home and it will show up here.')
                : 'No orders match this filter.',
            textAlign: TextAlign.center,
            style: AppText.small12,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.wine700 : AppColors.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body14Medium.copyWith(
              color:
              selected ? AppColors.textOnBrand : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    this.viewerId,
  });

  final Order order;
  final String? viewerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final service = order.service;
    // Freelancers see the client's name; clients see the freelancer's.
    final otherName = viewerId == order.freelancerId
        ? order.clientName
        : service.freelancerName;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: order.status),
                  Text(
                    formatPeso(order.amount),
                    style: AppText.title16.copyWith(color: AppColors.wine700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                service.title,
                style: AppText.label14,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.wine500,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initialsOf(otherName),
                      style: AppText.caption11.copyWith(
                        color: AppColors.textOnBrand,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$otherName · ${shortDate(order.createdAt)} · '
                          '${service.deliveryDays} days',
                      style: AppText.small12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (order.isActive) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.wine700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment held by CommiLink until the work is confirmed.',
                        style: AppText.small12.copyWith(
                          color: AppColors.wine700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}