import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';

/// Page 09 · Wallet (Figma node 8:446)
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openTopUp(BuildContext context) async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _TopUpSheet(),
    );
    if (amount != null && context.mounted) {
      AppState.instance.topUp(amount);
      _toast(context, 'MockPay top-up of ${formatPeso(amount)} successful.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Wallet'),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  [state.balance, state.orders, state.transactions],
                ),
                builder: (context, _) {
                  final txns = state.transactions.value;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(context, state),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.north_east_rounded,
                                label: 'Spent this month',
                                value: formatPeso(state.spent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.replay_rounded,
                                label: 'Refunded',
                                value: formatPeso(state.refunded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Recent activity', style: AppText.title16),
                        const SizedBox(height: 12),
                        if (txns.isEmpty)
                          _buildEmpty()
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < txns.length; i++) ...[
                                  _TxnRow(txn: txns[i]),
                                  if (i < txns.length - 1)
                                    const Divider(
                                      color: AppColors.border,
                                      height: 1,
                                    ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppState state) {
    final held = state.held;
    final count = state.activeCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: AppColors.wine900,
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0x1FFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available balance',
                          style: AppText.small12.copyWith(
                            color: const Color(0xB8FFFFFF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatPeso(state.balance.value)}.00',
                          style: AppText.heading24.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'MockPay',
                        style: AppText.caption11.copyWith(
                          color: AppColors.textOnBrand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.peach400,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          count == 0
                              ? 'Nothing on hold right now'
                              : '${formatPeso(held)} on hold for '
                              '$count commission${count == 1 ? '' : 's'}',
                          style: AppText.small12.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CardButton(
                        label: 'Top up',
                        icon: Icons.add_rounded,
                        filled: true,
                        onTap: () => _openTopUp(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CardButton(
                        label: 'Withdraw',
                        icon: Icons.north_east_rounded,
                        filled: false,
                        onTap: () => _toast(
                          context,
                          'Withdraw is not part of the demo.',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 30,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text('No activity yet', style: AppText.title16),
          const SizedBox(height: 4),
          Text(
            'Top-ups and held payments will show up here.',
            textAlign: TextAlign.center,
            style: AppText.small12,
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.wine900 : AppColors.textOnBrand;

    return Material(
      color: filled ? AppColors.peach400 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: Color(0x4DFFFFFF)),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label, style: AppText.label14.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.wine700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.caption11,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(value, style: AppText.title16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final WalletTxn txn;

  @override
  Widget build(BuildContext context) {
    final incoming = txn.amount > 0;
    final sign = incoming ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: incoming ? const Color(0xFFDDF0E6) : AppColors.peach100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              incoming ? Icons.south_west_rounded : Icons.lock_outline_rounded,
              size: 18,
              color: incoming ? const Color(0xFF2F7D5B) : AppColors.wine700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.title, style: AppText.label14),
                Text(
                  '${txn.subtitle} · ${shortDate(txn.date)}',
                  style: AppText.caption11,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${formatPeso(txn.amount.abs())}',
            style: AppText.label14.copyWith(
              color: incoming ? const Color(0xFF2F7D5B) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for the MockPay demo top-up.
class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const List<int> _amounts = [500, 1000, 5000, 10000];

  int _selected = 1000;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Top up wallet', style: AppText.heading20),
            const SizedBox(height: 4),
            Text(
              'MockPay is a simulation. No real money is used.',
              style: AppText.small12,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in _amounts)
                  ChoiceChip(
                    label: Text(
                      formatPeso(amount),
                      style: AppText.body14Medium.copyWith(
                        color: amount == _selected
                            ? AppColors.textOnBrand
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: amount == _selected,
                    showCheckmark: false,
                    selectedColor: AppColors.wine700,
                    backgroundColor: AppColors.surface,
                    side: amount == _selected
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.border),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    onSelected: (_) => setState(() => _selected = amount),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CtaButton(
              label: 'Top up ${formatPeso(_selected)}',
              icon: Icons.add_card_rounded,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}