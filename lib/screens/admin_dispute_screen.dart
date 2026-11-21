import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';
import '../widgets/initials_avatar.dart';

/// NEW PAGE · 27 · Admin — dispute review (Figma node 11:1728)
/// Admin reads both sides and either pays the freelancer or refunds the
/// client (database function `resolve_dispute`).
class AdminDisputeScreen extends StatefulWidget {
  const AdminDisputeScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminDisputeScreen> createState() => _AdminDisputeScreenState();
}

class _AdminDisputeScreenState extends State<AdminDisputeScreen> {
  final _state = AppState.instance;
  List<OrderFile> _files = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await SocialState.instance.loadOrderFiles(widget.orderId);
      if (mounted) setState(() => _files = files);
    } on AppException catch (_) {}
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _decide(Order order, {required bool refund}) async {
    final first = (refund ? order.clientName : order.service.freelancerName)
        .split(' ')
        .first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          refund ? 'Refund $first in full?' : 'Release to $first?',
          style: AppText.heading20,
        ),
        content: Text(
          refund
              ? '${formatPeso(order.amount)} goes back to the client’s wallet.'
              : '${formatPeso(order.amount)} goes to the freelancer’s wallet.',
          style: AppText.body14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _state.resolveDispute(order, refund: refund);
      _toast(refund ? 'Client refunded.' : 'Payment released to freelancer.');
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<Order>>(
          valueListenable: _state.orders,
          builder: (context, _, __) {
            final order = _state.findOrder(widget.orderId);
            if (order == null) {
              return const Center(child: Text('Dispute not found'));
            }
            final open = order.status == 'Disputed';
            final opened = order.disputedAt;

            return Column(
              children: [
                AppTopBar(title: 'Dispute ${disputeCode(order.disputeNumber)}'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.wine900,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.gavel_rounded,
                                    size: 14, color: AppColors.peach400),
                                const SizedBox(width: 6),
                                Text('Admin',
                                    style: AppText.caption11
                                        .copyWith(color: AppColors.peach400)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (opened != null)
                            Text(
                              'Opened ${shortDate(opened)} · ${clockTime(opened)}',
                              style: AppText.caption11,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _amountCard(order, open),
                      const SizedBox(height: 14),
                      _partiesCard(order),
                      const SizedBox(height: 14),
                      _statementsCard(order),
                    ],
                  ),
                ),
                if (open)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CtaButton(
                          label:
                              'Release ${formatPeso(order.amount)} to ${order.service.freelancerName.split(' ').first}',
                          icon: Icons.check_rounded,
                          onPressed:
                              _busy ? null : () => _decide(order, refund: false),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _decide(order, refund: true),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.wine700, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Refund ${order.clientName.split(' ').first} in full',
                              style: AppText.label14
                                  .copyWith(color: AppColors.wine700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      );

  Widget _amountCard(Order order, bool open) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0x1AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open
                      ? 'Amount on hold'
                      : (order.resolution == 'refunded'
                          ? 'Refunded to client'
                          : 'Released to freelancer'),
                  style: AppText.small12.copyWith(color: AppColors.peach400),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatPeso(order.amount)}.00',
                  style: AppText.display32.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  order.service.title,
                  style:
                      AppText.small12.copyWith(color: const Color(0xCCFFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partiesCard(Order order) {
    final delivered = order.deliveredAt;
    final replied = order.disputeResponse != null;

    Widget row(String name, String title, String sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              InitialsAvatar(name: name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.small12Medium
                            .copyWith(color: AppColors.textPrimary)),
                    Text(sub, style: AppText.caption11),
                  ],
                ),
              ),
            ],
          ),
        );

    return _card(Column(
      children: [
        row(order.clientName, '${order.clientName} · Client',
            'Reported: ${order.disputeReason ?? '—'}'),
        row(
          order.service.freelancerName,
          '${order.service.freelancerName} · Freelancer',
          [
            if (delivered != null) 'Delivered ${shortDate(delivered)}',
            replied ? 'replied' : 'no reply yet',
          ].join(' · '),
        ),
      ],
    ));
  }

  Widget _statementsCard(Order order) {
    final evidence =
        _files.where((f) => f.kind == 'delivery' || f.kind == 'dispute').toList();

    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Client statement', style: AppText.label14),
        const SizedBox(height: 6),
        Text(
          order.disputeNote ?? '—',
          style: AppText.small12.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 14),
        Text('Freelancer response', style: AppText.label14),
        const SizedBox(height: 6),
        Text(
          order.disputeResponse ?? 'The freelancer has not replied yet.',
          style: AppText.small12.copyWith(color: AppColors.textSecondary),
        ),
        if (order.deliveryNote != null) ...[
          const SizedBox(height: 10),
          Text('Delivery note: ${order.deliveryNote}',
              style: AppText.caption11),
        ],
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in evidence)
                ActionChip(
                  avatar: Icon(
                    f.name.toLowerCase().endsWith('.png') ||
                            f.name.toLowerCase().endsWith('.jpg')
                        ? Icons.image_outlined
                        : Icons.attach_file_rounded,
                    size: 16,
                    color: AppColors.wine700,
                  ),
                  label: Text(f.name, style: AppText.small12Medium),
                  backgroundColor: AppColors.peach100,
                  side: BorderSide.none,
                  onPressed: () async {
                    try {
                      await SocialState.instance.openFile(f);
                    } on AppException catch (e) {
                      _toast(e.message);
                    }
                  },
                ),
            ],
          ),
        ],
      ],
    ));
  }
}
