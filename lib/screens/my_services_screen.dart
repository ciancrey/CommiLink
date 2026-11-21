import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';
import 'post_service_screen.dart';

/// NEW PAGE · My services (freelancers only).
/// Lists the freelancer's own services and lets them hide/show each one.
class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  Future<void> _toggle(
    BuildContext context,
    Service service,
    bool active,
  ) async {
    try {
      await AppState.instance.setServiceActive(service, active);
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'My services'),
            Expanded(
              child: ValueListenableBuilder<List<Service>>(
                valueListenable: state.myServices,
                builder: (context, services, _) {
                  if (services.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'You have not posted a service yet.\n'
                          'Post one so clients can hire you.',
                          textAlign: TextAlign.center,
                          style: AppText.body14.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = services[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title, style: AppText.label14),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.category} · ${formatPeso(s.price)} · '
                                    '${s.deliveryDays} days · '
                                    '${s.reviewCount == 0 ? 'No reviews yet' : '${s.rating.toStringAsFixed(1)} ★ (${s.reviewCount})'}',
                                    style: AppText.small12,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.isActive
                                        ? 'Visible to clients'
                                        : 'Hidden',
                                    style: AppText.caption11.copyWith(
                                      color: s.isActive
                                          ? AppColors.wine700
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: s.isActive,
                              activeThumbColor: AppColors.wine700,
                              onChanged: (v) => _toggle(context, s, v),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: CtaButton(
                label: 'Post a new service',
                icon: Icons.add_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostServiceScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
