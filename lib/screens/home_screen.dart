import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/service_card.dart';
import 'freelancer_profile_screen.dart';
import 'request_commission_screen.dart';
import 'wallet_screen.dart';

/// Page 04 · Home (Hire) (Figma node 7:123)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'All',
    'Design',
    'Programming',
    'Video',
    'Writing',
  ];

  final _searchController = TextEditingController();
  String _category = 'All';
  String _query = '';

  final _state = AppState.instance;

  /// The signed-in user's name from the database.
  String get _userName => _state.userName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _initials => initialsOf(_userName);

  List<Service> get _filtered {
    final q = _query.trim().toLowerCase();
    return _state.services.value.where((s) {
      final matchesCategory = _category == 'All' || s.category == _category;
      final matchesQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.freelancerName.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _seeAll() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = 'All';
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    try {
      await _state.refresh();
    } on AppException catch (e) {
      _message(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when services or the profile are (re)loaded from Supabase.
    return AnimatedBuilder(
      animation: Listenable.merge([_state.services, _state.profile]),
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final services = _filtered;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.wine700,
        onRefresh: _refresh,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppText.heading24,
                      children: [
                        const TextSpan(text: 'Find the right '),
                        TextSpan(
                          text: 'freelancer',
                          style: AppText.heading24.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.wine500,
                          ),
                        ),
                        const TextSpan(text: '\nfor your next project'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSearch(),
                  const SizedBox(height: 18),
                  _buildCategories(),
                  const SizedBox(height: 18),
                  _buildBanner(),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Popular services', style: AppText.title16),
                      GestureDetector(
                        onTap: _seeAll,
                        child: Text(
                          'See all',
                          style: AppText.small12Medium.copyWith(
                            color: AppColors.wine700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (services.isEmpty)
                    _buildEmpty()
                  else
                    for (final service in services) ...[
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FreelancerProfileScreen(service: service),
                          ),
                        ),
                        child: ServiceCard(
                          service: service,
                          onRequest: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RequestCommissionScreen(service: service),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Tap the avatar to open the side drawer (MainShell's drawer).
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.wine500,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials,
                  style:
                      AppText.label14.copyWith(color: AppColors.textOnBrand),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppText.small12),
                Text(
                  _userName,
                  style: AppText.title16,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: AppColors.wine700,
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: AppState.instance.balance,
                    builder: (context, balance, _) => Text(
                      formatPeso(balance),
                      style: AppText.label14.copyWith(
                        color: AppColors.wine700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: AppText.body14,
                    cursorColor: AppColors.wine700,
                    decoration: InputDecoration(
                      hintText: 'Search services or freelancers',
                      hintStyle: AppText.body14.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.wine700,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _message('More filters are not part of the demo.'),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppColors.textOnBrand,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final category in _categories) ...[
            _CategoryChip(
              label: category,
              selected: category == _category,
              onTap: () => setState(() => _category = category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay safely, every time',
                  style: AppText.title16.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We hold your payment until you confirm the work.',
                  style: AppText.small12.copyWith(
                    color: const Color(0xB8FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.peach400,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 24,
              color: AppColors.wine900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            _state.services.value.isEmpty
                ? 'No services yet'
                : 'No services found',
            style: AppText.title16,
          ),
          const SizedBox(height: 4),
          Text(
            _state.services.value.isEmpty
                ? 'Freelancers haven\u2019t posted any services yet. '
                    'Pull down to refresh.'
                : 'Try a different keyword or category.',
            textAlign: TextAlign.center,
            style: AppText.small12,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.wine700 : AppColors.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body14Medium.copyWith(
              color: selected
                  ? AppColors.textOnBrand
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}