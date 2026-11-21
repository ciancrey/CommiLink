import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'create_account_screen.dart';
import 'sign_in_screen.dart';

/// Page 01 · Welcome (Figma node 6:3)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _bg = AppColors.wine900;
  static const Color _onDark72 = Color(0xB8FFFFFF);
  static const Color _onDark30 = Color(0x4DFFFFFF);

  double _deg(double d) => d * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          style: AppText.display32.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                          children: [
                            const TextSpan(text: 'Commission with\n'),
                            TextSpan(
                              text: 'confidence.',
                              style: AppText.display32.copyWith(
                                color: AppColors.peach400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Find trusted freelancers, request work, and pay safely. '
                            'CommiLink holds your payment until you confirm the work.',
                        style: AppText.body14.copyWith(color: _onDark72),
                      ),
                      const SizedBox(height: 16),
                      _buildPager(),
                      const SizedBox(height: 24),
                      _buildGetStarted(context),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          ),
                          child: Text(
                            'I already have an account',
                            style: AppText.label14.copyWith(
                              color: AppColors.textOnBrand,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- hero

  Widget _buildHero() {
    return SizedBox(
      height: 380,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            // Soft background circles.
            Positioned(
              left: 150,
              top: -90,
              child: Container(
                width: 380,
                height: 380,
                decoration: const BoxDecoration(
                  color: Color(0xFF5A0F2D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -70,
              top: 210,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFF5B2A2F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Service preview card (tilted right).
            Positioned(
              left: 12,
              top: 36,
              width: 275,
              height: 291,
              child: Center(
                child: Transform.rotate(
                  angle: _deg(6),
                  child: _buildServicePreview(),
                ),
              ),
            ),
            // "Payment held safely" chip (tilted left).
            Positioned(
              left: 178,
              top: 215,
              width: 198,
              height: 81,
              child: Center(
                child: Transform.rotate(
                  angle: _deg(-5),
                  child: _buildHeldChip(),
                ),
              ),
            ),
            // "Work confirmed" chip (tilted right).
            Positioned(
              left: 28,
              top: 316,
              width: 223,
              height: 50,
              child: Center(
                child: Transform.rotate(
                  angle: _deg(3),
                  child: _buildReviewChip(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<BoxShadow> _floatShadow = [
    BoxShadow(
      color: Color(0x383E0A1F),
      offset: Offset(0, 14),
      blurRadius: 30,
    ),
  ];

  Widget _buildServicePreview() {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _floatShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F7D5B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'MS',
                  style: AppText.small12Medium.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maria Santos', style: AppText.label14),
                  Text(
                    'Graphic Designer',
                    style: AppText.caption11.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 96,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCEEE1), Color(0xFFF5E1E6)],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: AppColors.wine500,
            ),
          ),
          const SizedBox(height: 12),
          Text('Clean, modern logo for your brand', style: AppText.label14),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill('₱1,500', AppColors.peach100, AppColors.wine700,
                  bold: true),
              const SizedBox(width: 8),
              _pill('5 days', AppColors.muted, AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {bool bold = false}) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: (bold ? AppText.label14 : AppText.small12Medium).copyWith(
          color: fg,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeldChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.peach400,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _floatShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.wine900,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.textOnBrand,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment held safely',
                style: AppText.caption11.copyWith(color: AppColors.wine900),
              ),
              Text(
                '₱6,500.00',
                style: AppText.title16.copyWith(color: AppColors.wine900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: _floatShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++) ...[
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: AppColors.peach400,
            ),
            if (i < 4) const SizedBox(width: 4),
          ],
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Work confirmed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small12Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- content

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 22,
              color: AppColors.wine700,
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              style: AppText.title16.copyWith(color: AppColors.textOnBrand),
              children: [
                const TextSpan(text: 'Commi'),
                TextSpan(
                  text: 'Link',
                  style: AppText.title16.copyWith(color: AppColors.peach400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPager() {
    Widget dot(bool active) => Container(
      width: active ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.peach400 : _onDark30,
        borderRadius: BorderRadius.circular(3),
      ),
    );

    return Row(
      children: [
        dot(true),
        const SizedBox(width: 6),
        dot(false),
        const SizedBox(width: 6),
        dot(false),
      ],
    );
  }

  Widget _buildGetStarted(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF6ECEA)],
        ),
        border: Border.all(color: AppColors.border),
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get started',
                style: AppText.title16.copyWith(color: AppColors.wine900),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.wine900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
