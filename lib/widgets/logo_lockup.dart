import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "CommiLink" logo + wordmark.
///
/// The mark is a placeholder icon for now. Once you export the real logo
/// from Figma, swap the Container child with an Image.
class LogoLockup extends StatelessWidget {
  const LogoLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF6DDE1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.link_rounded,
            color: AppColors.wine700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Commi',
                style: AppText.heading20.copyWith(color: AppColors.wine900),
              ),
              TextSpan(
                text: 'Link',
                style: AppText.heading20.copyWith(color: AppColors.wine500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}