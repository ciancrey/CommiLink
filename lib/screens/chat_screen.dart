import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/status_badge.dart';
import 'order_detail_screen.dart';

/// NEW PAGE · 23 · Chat (Figma node 11:1287)
/// Messages for one commission. Data: `messages` table (+ realtime).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _social = SocialState.instance;
  final _app = AppState.instance;
  final _textController = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessage> _messages = [];
  PlatformFile? _pendingFile;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _social.messageTick.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _social.messageTick.removeListener(_load);
    _textController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    try {
      final list = await _social.loadMessages(widget.orderId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToEnd();
      if (list.any((m) => m.senderId != _social.myId && m.readAt == null)) {
        await _social.markChatRead(widget.orderId);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.message);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _attach() async {
    try {
      final f = await _social.pickFile();
      if (f != null) setState(() => _pendingFile = f);
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if ((text.isEmpty && _pendingFile == null) || _sending) return;

    setState(() => _sending = true);
    try {
      await _social.sendMessage(widget.orderId, text, file: _pendingFile);
      _textController.clear();
      setState(() => _pendingFile = null);
      await _load();
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openOrder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: widget.orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<Order>>(
          valueListenable: _app.orders,
          builder: (context, _, __) {
            final order = _app.findOrder(widget.orderId);
            final me = _social.myId;
            final otherName = order == null
                ? ''
                : (me == order.freelancerId
                    ? order.clientName
                    : order.service.freelancerName);
            final otherRole =
                order == null || me == order.freelancerId ? 'Client' : 'Freelancer';

            return Column(
              children: [
                _buildHeader(otherName, otherRole),
                if (order != null) _buildOrderCard(order),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.wine700,
                          ),
                        )
                      : _buildMessages(me),
                ),
                _buildInput(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String role) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          InitialsAvatar(name: name, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.title16, overflow: TextOverflow.ellipsis),
                Text(role, style: AppText.caption11),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'Open commission',
            onTap: _openOrder,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openOrder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.peach100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      size: 20, color: AppColors.wine700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.service.title,
                        style: AppText.small12Medium
                            .copyWith(color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StatusBadge(status: order.status),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              order.isActive
                                  ? '${formatPeso(order.amount)} held'
                                  : formatPeso(order.amount),
                              style: AppText.small12Medium
                                  .copyWith(color: AppColors.wine700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(String? me) {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No messages yet.\nSay hi and talk about the details here.',
            textAlign: TextAlign.center,
            style: AppText.body14.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final children = <Widget>[];
    DateTime? lastDay;
    for (final m in _messages) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDay == null || day != lastDay) {
        children.add(_DayChip(date: day));
        lastDay = day;
      }
      children.add(_Bubble(
        message: m,
        mine: m.senderId == me,
        onOpenFile: (f) async {
          try {
            await _social.openFile(f);
          } on AppException catch (e) {
            _toast(e.message);
          }
        },
      ));
    }

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: children,
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.attach_file_rounded,
                      size: 16, color: AppColors.wine700),
                  label: Text(
                    '${_pendingFile!.name} · ${fileSize(_pendingFile!.size)}',
                    style: AppText.small12Medium,
                  ),
                  backgroundColor: AppColors.peach100,
                  side: BorderSide.none,
                  onDeleted: () => setState(() => _pendingFile = null),
                ),
              ),
            ),
          Row(
            children: [
              RoundIconButton(
                icon: Icons.add_rounded,
                size: 52,
                tooltip: 'Attach a file',
                onTap: _sending ? null : _attach,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: AppText.body14,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: AppText.body14
                          .copyWith(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: AppColors.peach400,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending ? null : _send,
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.wine900,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            size: 20, color: AppColors.wine900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : shortDate(date);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AppText.caption11),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.onOpenFile,
  });

  final ChatMessage message;
  final bool mine;
  final ValueChanged<OrderFile> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? AppColors.textOnBrand : AppColors.textPrimary;
    final sub = mine ? const Color(0xCCFFFFFF) : AppColors.textTertiary;
    final time = clockTime(message.createdAt) +
        (mine && message.readAt != null ? ' · Seen' : '');

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.wine700 : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(mine ? 20 : 6),
              bottomRight: Radius.circular(mine ? 6 : 20),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.file != null)
                GestureDetector(
                  onTap: () => onOpenFile(message.file!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0x33FFFFFF)
                              : AppColors.peach100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.attach_file_rounded,
                            size: 20,
                            color: mine ? Colors.white : AppColors.wine700),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.file!.name,
                              style: AppText.small12Medium.copyWith(color: fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${fileSize(message.file!.sizeBytes)} · '
                              '${fileType(message.file!.name)}',
                              style: AppText.caption11.copyWith(color: sub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.file != null && message.body.isNotEmpty)
                const SizedBox(height: 8),
              if (message.body.isNotEmpty)
                Text(message.body, style: AppText.body14.copyWith(color: fg)),
              const SizedBox(height: 4),
              Text(time, style: AppText.caption11.copyWith(color: sub)),
            ],
          ),
        ),
      ),
    );
  }
}
