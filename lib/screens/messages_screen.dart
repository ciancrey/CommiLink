import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/round_icon_button.dart';
import 'chat_screen.dart';

/// NEW PAGE · 22 · Messages (Figma node 11:1183)
/// One conversation per commission. Data: `conversations` view.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _social = SocialState.instance;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    try {
      await _social.refresh();
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  void _openChat(String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(orderId: orderId)),
    );
  }

  /// Compose button: pick which commission to message about.
  void _startChat(List<Conversation> all) {
    if (all.isEmpty) {
      _toast('Chats open once you have a commission. Request a service first.');
      return;
    }
    final me = _social.myId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          children: [
            Text('Message about…', style: AppText.heading20),
            const SizedBox(height: 12),
            for (final c in all)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: InitialsAvatar(name: c.otherName(me), size: 40),
                title: Text(c.otherName(me), style: AppText.label14),
                subtitle: Text(
                  c.serviceTitle,
                  style: AppText.small12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _openChat(c.orderId);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<List<Conversation>>(
        valueListenable: _social.conversations,
        builder: (context, all, _) {
          final me = _social.myId;
          final q = _query.trim().toLowerCase();
          final list = q.isEmpty
              ? all
              : all
                  .where((c) =>
                      c.otherName(me).toLowerCase().contains(q) ||
                      c.serviceTitle.toLowerCase().contains(q) ||
                      c.preview.toLowerCase().contains(q))
                  .toList();

          return RefreshIndicator(
            color: AppColors.wine700,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Messages', style: AppText.heading24),
                          const SizedBox(height: 2),
                          Text(
                            'Chats are linked to each commission',
                            style: AppText.small12,
                          ),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'New message',
                      onTap: () => _startChat(all),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SearchField(
                  controller: _searchController,
                  hint: 'Search conversations',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  _Empty(
                    title: all.isEmpty ? 'No chats yet' : 'No matches',
                    text: all.isEmpty
                        ? 'When you request or accept a commission, its chat '
                            'shows up here.'
                        : 'Try a different name or keyword.',
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _ConversationRow(
                            conversation: list[i],
                            myId: me,
                            onTap: () => _openChat(list[i].orderId),
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
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  final Conversation conversation;
  final String? myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;
    final name = c.otherName(myId);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InitialsAvatar(name: name, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppText.title16,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        friendlyTime(c.lastAt),
                        style: unread
                            ? AppText.caption11.copyWith(
                                color: AppColors.wine700,
                                fontWeight: FontWeight.w600,
                              )
                            : AppText.caption11,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.serviceTitle,
                    style: AppText.small12.copyWith(color: AppColors.wine500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small12.copyWith(
                            color: unread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.wine700,
                            borderRadius: BorderRadius.all(Radius.circular(11)),
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            style: AppText.caption11
                                .copyWith(color: AppColors.textOnBrand),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded white search box used by Messages and Network.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.body14,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppText.body14.copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 32, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: AppText.title16),
          const SizedBox(height: 4),
          Text(text, textAlign: TextAlign.center, style: AppText.small12),
        ],
      ),
    );
  }
}
