import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Floating pill-shaped bottom navigation (Figma "Bottom Nav").
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.messagesDot = false,
    this.alertsDot = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Peach dot when there are unread chat messages / alerts.
  final bool messagesDot;
  final bool alertsDot;

  static const List<_NavItem> _items = [
    _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Network', Icons.people_outline_rounded, Icons.people_rounded),
    _NavItem('Orders', Icons.work_outline_rounded, Icons.work_rounded),
    _NavItem(
      'Messages',
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
    ),
    _NavItem(
      'Alerts',
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x383E0A1F),
            offset: Offset(0, 14),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++)
            _NavButton(
              item: _items[i],
              selected: i == currentIndex,
              showDot: (i == 3 && messagesDot) || (i == 4 && alertsDot),
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content;

    if (selected) {
      content = Container(
        height: 52,
        padding: const EdgeInsets.only(left: 16, right: 20),
        decoration: BoxDecoration(
          color: AppColors.peach400,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.activeIcon, size: 22, color: AppColors.wine900),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: AppText.small12Medium.copyWith(
                color: AppColors.wine900,
              ),
            ),
          ],
        ),
      );
    } else {
      content = SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(item.icon, size: 22, color: const Color(0xB8FFFFFF)),
            if (showDot)
              Positioned(
                top: 12,
                right: 13,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.peach400,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wine900, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
