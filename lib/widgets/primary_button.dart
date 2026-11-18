import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Main wine-colored gradient button ("CTA Pill" in Figma).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ctaTop, AppColors.ctaBottom],
          ),
          border: Border.all(color: const Color(0x4DFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x473E0A1F),
              offset: Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.title16.copyWith(
                      color: AppColors.textOnBrand,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, color: AppColors.textOnBrand, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}