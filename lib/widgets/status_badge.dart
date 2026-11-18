import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small colored pill that shows an order status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'In progress':
        bg = AppColors.muted;
        fg = AppColors.textSecondary;
        break;
      case 'Delivered':
        bg = const Color(0xFFE3ECFA);
        fg = const Color(0xFF2B5CA8);
        break;
      case 'Completed':
        bg = const Color(0xFFDDF0E6);
        fg = const Color(0xFF2F7D5B);
        break;
      case 'Disputed':
      case 'Refunded':
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      default: // Requested
        bg = AppColors.peach100;
        fg = AppColors.wine700;
    }

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: AppText.caption11.copyWith(color: fg)),
    );
  }
}