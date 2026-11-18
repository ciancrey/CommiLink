import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Wine gradient call-to-action button (Figma "CTA Pill").
/// Pass onPressed: null to show it disabled.
class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ctaTop, AppColors.ctaBottom],
          ),
          border: Border.all(color: const Color(0x4DFFFFFF)),
          boxShadow: enabled
              ? const [
            BoxShadow(
              color: Color(0x473E0A1F),
              offset: Offset(0, 6),
              blurRadius: 14,
            ),
          ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.textOnBrand),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: AppText.title16.copyWith(color: AppColors.textOnBrand),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}