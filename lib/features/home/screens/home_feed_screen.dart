import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../widgets/filter_bar.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_video_showcase.dart';
import '../widgets/listing_card.dart';
import '../widgets/partner_logos_row.dart';
import '../widgets/zone_card_row.dart';
import 'all_listings_screen.dart';
import 'smart_search_screen.dart';

const _maxPreviewCards = 6;

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final HomeFilterState _filterState = HomeFilterState();
  String _zoneHighlight = 'هەموو';

  void _openSearch() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.expressive,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: const SmartSearchScreen(),
        ),
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('home.no_new_notifications'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = MockData.listings.where((listing) {
      return _filterState.type == 'all' || listing.type.name == _filterState.type;
    }).toList()
      ..sort((a, b) {
        final featuredOrder = (b.featured ? 1 : 0) - (a.featured ? 1 : 0);
        return featuredOrder != 0
            ? featuredOrder
            : b.createdAt.compareTo(a.createdAt);
      });
    final preview = listings.take(_maxPreviewCards).toList();

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(onNotifications: _showNotifications, onSearchTap: _openSearch),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(child: HeroBanner(onExplore: _openSearch)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 0, 0),
              sliver: SliverToBoxAdapter(child: RepaintBoundary(child: const PartnerLogosRow())),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 11),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home.featured_zones_title'.tr(),
                  subtitle: 'home.featured_zones_subtitle'.tr(),
                  icon: Icons.location_on_outlined,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              sliver: SliverToBoxAdapter(
                child: ZoneCardRow(
                  selected: _zoneHighlight,
                  onSelect: (zone) => setState(() => _zoneHighlight = zone),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 11),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home.what_are_you_looking_for'.tr(),
                  subtitle: 'home.choose_property_type'.tr(),
                  icon: Icons.category_outlined,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              sliver: SliverToBoxAdapter(
                child: FilterBar(
                  state: _filterState,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 13),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home.featured_listings_title'.tr(),
                  subtitle: 'home.listings_available'.tr(args: ['${listings.length}']),
                  icon: Icons.auto_awesome_outlined,
                  actionLabel: listings.length > _maxPreviewCards ? 'home.view_all'.tr() : null,
                  onAction: listings.length > _maxPreviewCards
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AllListingsScreen(
                                typeFilter: _filterState.type,
                              ),
                            ),
                          )
                      : null,
                ),
              ),
            ),
            if (preview.isEmpty)
              SliverToBoxAdapter(child: _EmptyListings(onReset: _resetFilter))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 700 ? 3 : 2;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: columns == 3 ? 0.76 : 0.66,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => ListingCard(
                          listing: preview[index],
                          animationIndex: index,
                        ),
                        childCount: preview.length,
                      ),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 13),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home.video_tour_title'.tr(),
                  subtitle: 'home.video_tour_subtitle'.tr(),
                  icon: Icons.videocam_outlined,
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: HomeVideoShowcase()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 125)),
          ],
        ),
      ),
    );
  }

  void _resetFilter() {
    setState(() => _filterState.type = 'all');
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onNotifications, required this.onSearchTap});

  final VoidCallback onNotifications;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          const ShikodarMark(size: 44, showShadow: false),
          const SizedBox(width: 11),
          Expanded(child: _CompactSearchBar(onTap: onSearchTap)),
          const SizedBox(width: 10),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: palette.divider),
              ),
              child: Icon(icon, color: palette.textPrimary, size: 20),
            ),
          ),
        ),
        if (showDot)
          PositionedDirectional(
            top: 8,
            end: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: palette.error,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _CompactSearchBar extends StatelessWidget {
  const _CompactSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: palette.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'common.search_hint'.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: palette.textMuted, size: 32),
            const SizedBox(height: 10),
            Text(
              'home.no_listings_found'.tr(),
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(onPressed: onReset, child: Text('home.reset_to_all'.tr())),
          ],
        ),
      ),
    );
  }
}
