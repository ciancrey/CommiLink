import 'package:flutter/material.dart';

import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// A freelancer's service listing card (Figma "Service Card").
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, this.onRequest});

  final Service service;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123E0A1F),
            offset: Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initials: service.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.freelancerName,
                      style: AppText.label14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      service.role,
                      style: AppText.small12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.peach400,
              ),
              const SizedBox(width: 4),
              Text(
                service.rating.toStringAsFixed(1),
                style: AppText.small12Medium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCEEE1), Color(0xFFF5E1E6)],
              ),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 32,
              color: AppColors.wine500,
            ),
          ),
          const SizedBox(height: 14),
          Text(service.title, style: AppText.title16),
          const SizedBox(height: 14),
          Text(service.description, style: AppText.small12),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: service.category),
              _Tag(text: '${service.deliveryDays} days delivery'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starts at', style: AppText.caption11),
                  Text(
                    formatPeso(service.price),
                    style: AppText.heading20.copyWith(
                      color: AppColors.wine700,
                    ),
                  ),
                ],
              ),
              _RequestButton(onPressed: onRequest),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.wine500,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppText.label14.copyWith(color: AppColors.textOnBrand),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: AppText.small12Medium),
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Container(
      height: 44,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Text(
                'Request',
                style: AppText.label14.copyWith(color: AppColors.textOnBrand),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
