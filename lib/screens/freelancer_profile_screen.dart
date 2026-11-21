import 'package:flutter/material.dart';

import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/cta_button.dart';
import 'request_commission_screen.dart';

/// Page 06 · Freelancer profile (Figma node 7:362)
class FreelancerProfileScreen extends StatelessWidget {
  const FreelancerProfileScreen({super.key, required this.service});

  final Service service;

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openRequest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestCommissionScreen(service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(context),
                  const SizedBox(height: 72),
                  _buildIdentity(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStats(),
                        const SizedBox(height: 16),
                        Text('About', style: AppText.title16),
                        const SizedBox(height: 6),
                        Text(
                          'I build quality work for clients across the '
                              'Philippines. ${service.description}',
                          style: AppText.body14.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Portfolio', style: AppText.title16),
                            GestureDetector(
                              onTap: () => _message(
                                context,
                                'Showing up to 3 portfolio images.',
                              ),
                              child: Text(
                                'See all',
                                style: AppText.small12Medium.copyWith(
                                  color: AppColors.wine700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPortfolio(),
                        const SizedBox(height: 16),
                        Text('Services', style: AppText.title16),
                        const SizedBox(height: 12),
                        _buildServiceRow(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 210,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.wine900, AppColors.wine700],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(
                    Icons.arrow_back_rounded,
                        () => Navigator.of(context).maybePop(),
                  ),
                  _roundButton(
                    Icons.favorite_border_rounded,
                        () => _message(context, 'Saved freelancers: coming later.'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -60,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.wine500,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 4),
              ),
              child: Text(
                service.initials,
                style: AppText.heading24.copyWith(
                  color: AppColors.textOnBrand,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  service.freelancerName,
                  style: AppText.heading20,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: AppColors.wine700,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            service.role,
            textAlign: TextAlign.center,
            style: AppText.small12,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    Widget cell(String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(value, style: AppText.title16),
              const SizedBox(height: 2),
              Text(label, style: AppText.caption11),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(
          service.reviewCount == 0
              ? 'New'
              : '${service.rating.toStringAsFixed(1)} ★',
          'Rating',
        ),
        const SizedBox(width: 10),
        cell('${service.reviewCount}', 'Reviews'),
        const SizedBox(width: 10),
        cell('${service.deliveryDays} days', 'Avg. delivery'),
      ],
    );
  }

  Widget _buildPortfolio() {
    final urls = service.imageUrls;

    Widget tile(String? url) {
      return Expanded(
        child: Container(
          height: 104,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCEEE1), Color(0xFFF5E1E6)],
            ),
          ),
          child: url == null
              ? const Icon(
                  Icons.image_outlined,
                  size: 24,
                  color: AppColors.wine500,
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.wine500,
                  ),
                ),
        ),
      );
    }

    // Real portfolio images from "Post a service" (placeholders if none).
    String? at(int i) => i < urls.length ? urls[i] : null;

    return Row(
      children: [
        tile(at(0)),
        const SizedBox(width: 10),
        tile(at(1)),
        const SizedBox(width: 10),
        tile(at(2)),
      ],
    );
  }


  Widget _buildServiceRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 22,
              color: AppColors.wine700,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  '${service.deliveryDays} days · from ${formatPeso(service.price)}',
                  style: AppText.small12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Material(
                color: AppColors.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      _message(context, 'Chat is coming in a later step.'),
                  child: const SizedBox(
                    width: 60,
                    height: 60,
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 22,
                      color: AppColors.wine700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CtaButton(
                  label: 'Request commission',
                  height: 60,
                  onPressed: () => _openRequest(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}