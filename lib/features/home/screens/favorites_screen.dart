import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/network/favorite_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../agency/screens/agency_profile_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../widgets/listing_card.dart';

/// Cross-screen favorites sync — a plain ValueNotifier<Set<String>> so any
/// heart icon anywhere in the app updates instantly when another one is
/// tapped. Persisted server-side via [FavoriteRepository]; [toggle] applies
/// the change optimistically and reverts it if the request fails.
class FavoritesStore {
  static final ValueNotifier<Set<String>> ids = ValueNotifier({});

  /// Seeds [ids] from the server — call after login and whenever the
  /// Favorites tab opens. Best-effort: a guest (401) just leaves it empty.
  static Future<void> loadFromServer(FavoriteRepository repository) async {
    try {
      ids.value = await repository.fetchIds();
    } catch (_) {
      // Not signed in, or offline — heart icons just stay unfilled.
    }
  }

  static Future<void> toggle(FavoriteRepository repository, {required String type, required String id}) async {
    final wasFavorited = ids.value.contains(id);
    ids.value = _with(ids.value, id, add: !wasFavorited);
    try {
      final favorited = await repository.toggle(type: type, id: id);
      ids.value = _with(ids.value, id, add: favorited);
    } catch (_) {
      ids.value = _with(ids.value, id, add: wasFavorited);
    }
  }

  static void clear() => ids.value = {};

  static Set<String> _with(Set<String> current, String id, {required bool add}) {
    final next = Set<String>.from(current);
    add ? next.add(id) : next.remove(id);
    return next;
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _tab = 0; // 0 posts, 1 accounts
  List<FavoriteEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final entries = await context.read<FavoriteRepository>().fetchAll();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
    // Keep the heart-icon store (used elsewhere in the app) in sync too.
    FavoritesStore.loadFromServer(context.read<FavoriteRepository>());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final posts = _entries.where((e) => e.type == 'listing' || e.type == 'project').toList();
    final accounts = _entries.where((e) => e.type == 'agency').toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('nav.favorites'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: _tabsBar(palette, postsCount: posts.length, accountsCount: accounts.length),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: palette.primary))
                  : (_tab == 0 ? _postsGrid(palette, posts) : _accountsList(palette, accounts)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabsBar(AppPalette palette, {required int postsCount, required int accountsCount}) {
    final labels = ['favorites_page.tab_posts'.tr(args: ['$postsCount']), 'favorites_page.tab_accounts'.tr(args: ['$accountsCount'])];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _tab == i;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: selected ? palette.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(labels[i], style: TextStyle(color: selected ? palette.background : palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState(AppPalette palette, IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: palette.textMuted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(text, style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _postsGrid(AppPalette palette, List<FavoriteEntry> posts) {
    if (posts.isEmpty) {
      return _emptyState(palette, Icons.favorite_border_rounded, 'favorites_page.empty_posts'.tr());
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final entry = posts[i];
        if (entry.type == 'listing') {
          return ListingCard(listing: Listing.fromJson(entry.data), animationIndex: i);
        }
        final project = Project.fromJson(entry.data);
        return _ProjectFavoriteTile(project: project);
      },
    );
  }

  Widget _accountsList(AppPalette palette, List<FavoriteEntry> accounts) {
    if (accounts.isEmpty) {
      return _emptyState(palette, Icons.storefront_outlined, 'favorites_page.empty_accounts'.tr());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final agency = Agency.fromJson(accounts[i].data);
        return _AccountFavoriteTile(agency: agency);
      },
    );
  }
}

class _ProjectFavoriteTile extends StatelessWidget {
  final Project project;
  const _ProjectFavoriteTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            project.images.isNotEmpty
                ? CachedNetworkImage(imageUrl: project.images.first, fit: BoxFit.cover, placeholder: (_, __) => Container(color: palette.surfaceElevated))
                : Container(color: palette.surfaceElevated, child: Icon(Icons.apartment_rounded, color: palette.textMuted)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x99000000)], stops: [0.5, 1]),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('\$${project.priceFrom.toStringAsFixed(0)}+', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFavoriteTile extends StatelessWidget {
  final Agency agency;
  const _AccountFavoriteTile({required this.agency});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgencyProfileScreen(agency: agency))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 52,
                height: 52,
                color: palette.surfaceElevated,
                child: agency.logoUrl != null && agency.logoUrl!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: agency.logoUrl!, fit: BoxFit.cover)
                    : Icon(Icons.storefront_rounded, color: palette.textMuted, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(agency.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800))),
                      if (agency.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text(agency.rating != null ? agency.rating!.toStringAsFixed(1) : '—', style: TextStyle(color: palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
