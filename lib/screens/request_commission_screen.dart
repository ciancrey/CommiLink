import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';

/// Page 07 / 08 · Request commission (+ low balance) (Figma 7:450, 7:524)
class RequestCommissionScreen extends StatefulWidget {
  const RequestCommissionScreen({super.key, required this.service});

  final Service service;

  @override
  State<RequestCommissionScreen> createState() =>
      _RequestCommissionScreenState();
}

class _RequestCommissionScreenState extends State<RequestCommissionScreen> {
  static const int _maxChars = 500;
  static const int _minChars = 10;

  final _briefController = TextEditingController();
  final _state = AppState.instance;
  bool _showError = false;
  bool _busy = false;
  final List<PlatformFile> _refFiles = [];

  Future<void> _addRefFile() async {
    if (_refFiles.length >= 5) {
      _toast('You can attach up to 5 files.');
      return;
    }
    try {
      final f = await SocialState.instance.pickFile();
      if (f != null) setState(() => _refFiles.add(f));
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  @override
  void dispose() {
    _briefController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _topUp(int shortfall) async {
    // Round up to the next ₱1,000 (MockPay minimum is ₱100).
    final amount = ((shortfall + 999) ~/ 1000) * 1000;
    setState(() => _busy = true);
    try {
      await _state.topUp(amount);
      _toast('MockPay top-up of ${formatPeso(amount)} successful (demo).');
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final brief = _briefController.text.trim();
    if (brief.length < _minChars) {
      setState(() => _showError = true);
      return;
    }

    setState(() => _busy = true);
    try {
      // Database function place_order: checks balance, holds the money,
      // creates the order and the wallet history line in one step.
      final orderId = await _state.placeOrder(widget.service, brief);

      // Upload reference files to the new commission (private storage).
      var failed = 0;
      for (final f in _refFiles) {
        try {
          await SocialState.instance.uploadOrderFile(orderId, 'brief', f);
        } on AppException catch (_) {
          failed++;
        }
      }
      if (!mounted) return;
      if (failed > 0) {
        _toast('$failed file(s) could not be uploaded. You can send them in the chat.');
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${formatPeso(widget.service.price)} is now held by CommiLink. '
              'Request sent to ${widget.service.freelancerName}.',
            ),
          ),
        );
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _state.balance,
          builder: (context, balance, _) {
            final enough = balance >= service.price;
            final shortfall = service.price - balance;

            return Column(
              children: [
                const AppTopBar(title: 'Request commission'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(service),
                        const SizedBox(height: 16),
                        Text('What do you need?', style: AppText.small12Medium),
                        const SizedBox(height: 6),
                        _buildBrief(),
                        const SizedBox(height: 16),
                        for (final f in _refFiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InputChip(
                              avatar: const Icon(Icons.attach_file_rounded,
                                  size: 16, color: AppColors.wine700),
                              label: Text(
                                '${f.name} · ${fileSize(f.size)}',
                                style: AppText.small12Medium,
                              ),
                              backgroundColor: AppColors.peach100,
                              side: BorderSide.none,
                              onDeleted: () =>
                                  setState(() => _refFiles.remove(f)),
                            ),
                          ),
                        GestureDetector(
                          onTap: _busy ? null : _addRefFile,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 18,
                                color: AppColors.wine700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add reference files',
                                style: AppText.small12Medium.copyWith(
                                  color: AppColors.wine700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPayment(service, balance),
                        const SizedBox(height: 16),
                        enough
                            ? _note(
                          icon: Icons.lock_outline_rounded,
                          text:
                          'Your payment is held by CommiLink and only '
                              'released after you confirm the work.',
                          bg: AppColors.peach100,
                          fg: AppColors.wine700,
                        )
                            : _note(
                          icon: Icons.error_outline_rounded,
                          text:
                          'Your wallet balance is not enough. You need '
                              '${formatPeso(shortfall)} more to send this request.',
                          bg: AppColors.dangerBg,
                          fg: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!enough) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _topUp(shortfall),
                            icon: const Icon(
                              Icons.add_card_rounded,
                              size: 20,
                              color: AppColors.wine700,
                            ),
                            label: Text(
                              'Top up wallet',
                              style: AppText.label14.copyWith(
                                color: AppColors.wine700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      CtaButton(
                        label: 'Send request · ${formatPeso(service.price)}',
                        icon: Icons.send_rounded,
                        onPressed: enough && !_busy ? _submit : null,
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

  Widget _buildSummary(Service service) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 24,
              color: AppColors.wine700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: AppText.label14,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.wine500,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        service.initials,
                        style: AppText.caption11.copyWith(
                          color: AppColors.textOnBrand,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${service.freelancerName} · ${service.deliveryDays} days delivery',
                        style: AppText.small12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrief() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _showError ? AppColors.danger : AppColors.border,
          width: _showError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _briefController,
            maxLength: _maxChars,
            maxLines: 4,
            minLines: 4,
            onChanged: (_) => setState(() => _showError = false),
            style: AppText.body14,
            cursorColor: AppColors.wine700,
            buildCounter: (_,
                {required currentLength,
                  required isFocused,
                  maxLength}) =>
            null,
            decoration: InputDecoration(
              hintText: 'Describe the work you need, with any details.',
              hintStyle: AppText.body14.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _showError
                ? 'Please describe your request (at least $_minChars characters)'
                : '${_briefController.text.length} / $_maxChars',
            style: AppText.caption11.copyWith(
              color: _showError ? AppColors.danger : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayment(Service service, int balance) {
    Widget row(String label, String value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: bold
                  ? AppText.label14
                  : AppText.body14.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: bold
                  ? AppText.title16.copyWith(color: AppColors.wine700)
                  : AppText.body14Medium,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment summary', style: AppText.label14),
          const SizedBox(height: 8),
          row('Service price', formatPeso(service.price)),
          row('Your wallet balance', formatPeso(balance)),
          const Divider(color: AppColors.border, height: 20),
          row('Total to hold', formatPeso(service.price), bold: true),
        ],
      ),
    );
  }

  Widget _note({
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
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
}