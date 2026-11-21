import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/social_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/round_icon_button.dart';
import 'freelancer_profile_screen.dart';

/// NEW PAGE · 26 · Network (Figma node 11:1625)
/// Lists every freelancer, best rated first. Data: `freelancer_directory`.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  /// Filter chip -> service category in the database.
  static const Map<String, String?> _filters = {
    'All': null,
    'Designers': 'Design',
    'Developers': 'Programming',
    'Editors': 'Video',
    'Writers': 'Writing',
  };

  final _searchController = TextEditingController();
  List<Freelancer> _all = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await SocialState.instance.loadFreelancers();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
        _error = null;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  List<Freelancer> get _visible {
    final cat = _filters[_filter];
    final q = _query.trim().toLowerCase();
    return _all.where((f) {
      final okCat = cat == null || f.categories.contains(cat);
      final okQ = q.isEmpty ||
          f.fullName.toLowerCase().contains(q) ||
          f.headline.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
  }

  /// "View" opens the freelancer's profile using their best service.
  void _view(Freelancer f) {
    final services = AppState.instance.services.value
        .where((s) => s.freelancerId == f.id)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (services.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${f.fullName} has not posted a service yet.'),
        ));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FreelancerProfileScreen(service: services.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.wine700,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Network', style: AppText.heading24),
                      const SizedBox(height: 2),
                      Text('Discover trusted freelancers',
                          style: AppText.small12),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                  tooltip: 'Search',
                  onTap: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) {
                      _searchController.clear();
                      _query = '';
                    }
                  }),
                ),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 14),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 20, color: AppColors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        style: AppText.body14,
                        decoration: InputDecoration(
                          hintText: 'Search freelancers',
                          hintStyle: AppText.body14
                              .copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _filters.keys) ...[
                    _Chip(
                      label: f,
                      selected: f == _filter,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Top rated this week', style: AppText.title16),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.wine700),
                ),
              )
            else if (_error != null)
              Text(_error!, style: AppText.small12)
            else if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  _all.isEmpty
                      ? 'No freelancers have joined yet.'
                      : 'No freelancers match this filter.',
                  textAlign: TextAlign.center,
                  style: AppText.body14
                      .copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              for (final f in list) ...[
                _FreelancerCard(freelancer: f, onView: () => _view(f)),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        side: selected ? BorderSide.none : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body14Medium.copyWith(
              color: selected ? AppColors.textOnBrand : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FreelancerCard extends StatelessWidget {
  const _FreelancerCard({required this.freelancer, required this.onView});

  final Freelancer freelancer;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final f = freelancer;
    final stats = f.reviewCount == 0
        ? 'New · ${f.jobsDone} jobs'
        : '${f.rating.toStringAsFixed(1)} · ${f.jobsDone} jobs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: f.fullName, imageUrl: f.avatarUrl, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.fullName,
                    style: AppText.title16, overflow: TextOverflow.ellipsis),
                Text(
                  f.headline.isEmpty ? 'Freelancer' : f.headline,
                  style: AppText.small12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.peach400),
                    const SizedBox(width: 4),
                    Text(stats, style: AppText.caption11),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.wine700, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'View',
              style: AppText.label14.copyWith(color: AppColors.wine700),
            ),
          ),
        ],
      ),
    );
  }
}

