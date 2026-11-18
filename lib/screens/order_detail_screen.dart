import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';
import '../widgets/status_badge.dart';

/// Pages 14 to 21 · One commission, from request to completed
/// (Figma frames 14 Requested ... 21 Completed + review).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const List<String> _steps = [
    'Requested',
    'In progress',
    'Delivered',
    'Completed',
  ];

  static const Color _green = Color(0xFF2F7D5B);

  final _state = AppState.instance;
  final _reviewController = TextEditingController();
  int _stars = 5;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  int _stage(String status) {
    switch (status) {
      case 'Requested':
        return 0;
      case 'In progress':
        return 1;
      case 'Delivered':
      case 'Disputed':
      case 'Refunded':
        return 2;
      default:
        return 3; // Completed
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmRelease(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.peach100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 30,
                  color: AppColors.wine700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Release ${formatPeso(order.amount)}?',
                style: AppText.heading20,
              ),
              const SizedBox(height: 8),
              Text(
                'The payment will be released to '
                    '${order.service.freelancerName}. This can\u2019t be undone.',
                textAlign: TextAlign.center,
                style: AppText.body14.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              CtaButton(
                label: 'Yes, release payment',
                height: 52,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Not yet',
                  style: AppText.label14.copyWith(color: AppColors.wine700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      _state.release(order);
      _toast('Payment released. Please leave a review.');
    }
  }

  Future<void> _openReport(Order order) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ReportSheet(),
    );

    if (result != null) {
      _state.dispute(order, result.$1, result.$2);
      _toast('Report sent. Your payment stays on hold.');
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
              return const Center(child: Text('Order not found'));
            }

            return Column(
              children: [
                const AppTopBar(title: 'Commission'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(order),
                        const SizedBox(height: 14),
                        _buildDetails(order),
                        if (order.disputedAt != null) ...[
                          const SizedBox(height: 14),
                          _buildDisputeTimeline(order),
                        ],
                        const SizedBox(height: 14),
                        _buildNote(order),
                        if (order.status == 'Completed') ...[
                          const SizedBox(height: 14),
                          _buildReview(order),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(order),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildSummary(Order order) {
    final service = order.service;
    final stage = _stage(order.status);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: order.status),
              Text(
                formatPeso(order.amount),
                style: AppText.heading20.copyWith(color: AppColors.wine700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(service.title, style: AppText.title16),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.wine500,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  service.initials,
                  style: AppText.caption11.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Freelancer', style: AppText.caption11),
                    Text(service.freelancerName, style: AppText.label14),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Ordered', style: AppText.caption11),
                  Text(
                    '${shortDate(order.createdAt)} · ${service.deliveryDays} days',
                    style: AppText.small12Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                Expanded(child: _stepDot(i, stage, order.status)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index, int stage, String status) {
    final done = index <= stage;
    final bad = (status == 'Disputed' || status == 'Refunded') && index == 2;

    final Color color = bad
        ? AppColors.danger
        : (done ? AppColors.wine700 : AppColors.border);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: index == 0
                    ? Colors.transparent
                    : (index <= stage ? AppColors.wine700 : AppColors.border),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                bad ? Icons.priority_high_rounded : Icons.check_rounded,
                size: 14,
                color: done || bad
                    ? AppColors.textOnBrand
                    : AppColors.surface,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: index == _steps.length - 1
                    ? Colors.transparent
                    : (index < stage ? AppColors.wine700 : AppColors.border),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _steps[index],
          textAlign: TextAlign.center,
          style: AppText.caption11.copyWith(
            fontSize: 10,
            color: done ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(Order order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request', style: AppText.label14),
          const SizedBox(height: 6),
          Text(
            order.brief,
            style: AppText.body14.copyWith(color: AppColors.textSecondary),
          ),
          if (order.deliveryNote != null) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            Text('Delivery note', style: AppText.label14),
            const SizedBox(height: 6),
            Text(
              order.deliveryNote!,
              style: AppText.body14.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: AppColors.wine700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'final-files.zip · 24 MB',
                    style: AppText.small12Medium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeTimeline(Order order) {
    final resolved = order.status != 'Disputed';

    Widget row(String title, String sub, {required bool done}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.wine700 : AppColors.peach100,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.textOnBrand,
              )
                  : const Icon(
                Icons.circle,
                size: 8,
                color: AppColors.wine700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label14),
                  Text(sub, style: AppText.caption11),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispute timeline', style: AppText.label14),
          const SizedBox(height: 14),
          row(
            'Report submitted',
            '${shortDate(order.disputedAt!)} · ${order.disputeReason}',
            done: true,
          ),
          row(
            resolved ? 'Reviewed by CommiLink' : 'Under review by CommiLink',
            resolved
                ? (order.status == 'Refunded'
                ? 'Decision: refunded to your wallet'
                : 'Decision: released to the freelancer')
                : 'Admin decides: release or refund',
            done: resolved,
          ),
        ],
      ),
    );
  }

  Widget _buildNote(Order order) {
    IconData icon = Icons.lock_outline_rounded;
    String text;
    Color bg = AppColors.peach100;
    Color fg = AppColors.wine700;

    switch (order.status) {
      case 'Requested':
        text = 'Waiting for ${order.service.freelancerName} to accept. '
            'Your payment is held by CommiLink.';
        break;
      case 'In progress':
        text = 'The freelancer is working on your request. Your payment '
            'stays on hold until you confirm the work.';
        break;
      case 'Delivered':
        text = 'Check the files. Release the payment only when you are '
            'happy, or report a problem.';
        break;
      case 'Disputed':
        text = 'Your payment stays on hold while CommiLink reviews the '
            'report.';
        break;
      case 'Refunded':
        icon = Icons.replay_rounded;
        text = '${formatPeso(order.amount)} was returned to your wallet.';
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      default:
        icon = Icons.check_circle_outline_rounded;
        text = 'Payment released to ${order.service.freelancerName}. '
            'Thank you for using CommiLink.';
        bg = const Color(0xFFDDF0E6);
        fg = _green;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.small12.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(Order order) {
    final done = order.rating != null;
    final rating = order.rating ?? _stars;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate ${order.service.freelancerName}',
            style: AppText.title16,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: done ? null : () => setState(() => _stars = i),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: AppColors.peach400,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (done)
            Text(
              order.review!.isEmpty ? 'Thanks for rating!' : order.review!,
              style: AppText.body14.copyWith(color: AppColors.textSecondary),
            )
          else ...[
            TextField(
              controller: _reviewController,
              maxLines: 3,
              style: AppText.body14,
              cursorColor: AppColors.wine700,
              decoration: InputDecoration(
                hintText: 'Write a short review (optional)',
                hintStyle: AppText.body14.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.wine700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CtaButton(
              label: 'Submit review',
              height: 52,
              onPressed: () {
                _state.submitReview(
                  order,
                  _stars,
                  _reviewController.text.trim(),
                );
                _toast('Thanks for your review!');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(Order order) {
    Widget? content;

    switch (order.status) {
      case 'Requested':
        content = _demoButton(
          'Freelancer accepts (demo)',
              () => _state.advance(order),
        );
        break;
      case 'In progress':
        content = _demoButton(
          'Freelancer delivers (demo)',
              () => _state.advance(order),
        );
        break;
      case 'Delivered':
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CtaButton(
              label: 'Confirm & release payment',
              icon: Icons.verified_user_outlined,
              onPressed: () => _confirmRelease(order),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _openReport(order),
                icon: const Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: AppColors.danger,
                ),
                label: Text(
                  'Report a problem',
                  style: AppText.label14.copyWith(color: AppColors.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
        break;
      case 'Disputed':
        content = Row(
          children: [
            Expanded(
              child: _demoButton(
                'Admin: release (demo)',
                    () => _state.resolveDispute(order, refund: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _demoButton(
                'Admin: refund (demo)',
                    () => _state.resolveDispute(order, refund: true),
              ),
            ),
          ],
        );
        break;
    }

    if (content == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: content,
    );
  }

  Widget _demoButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.wine700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.label14.copyWith(color: AppColors.wine700),
        ),
      ),
    );
  }
}

/// Bottom sheet for "Report a problem". Returns (reason, details).
class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const List<String> _reasons = [
    'Not as described',
    'Late delivery',
    'Poor quality',
    'Other',
  ];

  final _controller = TextEditingController();
  String? _reason;
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _controller.text.trim();
    if (_reason == null || note.length < 10) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop((_reason!, note));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottom),
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
            Text('Report a problem', style: AppText.heading20),
            const SizedBox(height: 4),
            Text(
              'Tell us what went wrong. Your payment stays on hold until '
                  'CommiLink resolves it.',
              style: AppText.small12,
            ),
            const SizedBox(height: 16),
            Text('Reason', style: AppText.label14),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(
                      r,
                      style: AppText.body14Medium.copyWith(
                        color: r == _reason
                            ? AppColors.textOnBrand
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: r == _reason,
                    showCheckmark: false,
                    selectedColor: AppColors.wine700,
                    backgroundColor: AppColors.surface,
                    side: r == _reason
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.border),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    onSelected: (_) => setState(() {
                      _reason = r;
                      _showError = false;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              onChanged: (_) => setState(() => _showError = false),
              style: AppText.body14,
              cursorColor: AppColors.wine700,
              decoration: InputDecoration(
                hintText: 'Describe the problem (at least 10 characters)',
                hintStyle: AppText.body14.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.wine700),
                ),
              ),
            ),
            if (_showError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Choose a reason and describe the problem.',
                  style: AppText.small12.copyWith(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 16),
            CtaButton(
              label: 'Submit report',
              icon: Icons.flag_outlined,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}