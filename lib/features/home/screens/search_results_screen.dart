import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_palette.dart';
import '../search_relevance.dart';
import '../widgets/listing_card.dart';
import 'smart_search_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    required this.allListings,
    required this.keyword,
    required this.criteria,
    required this.sort,
  });

  final List<Listing> allListings;
  final String keyword;
  final SearchCriteria criteria;
  final SortOption sort;

  String get zone => criteria.zone;
  ListingPurpose? get purpose => criteria.purpose;
  String get type => criteria.type;
  int? get rooms => criteria.rooms;
  bool get verifiedOnly => criteria.verifiedOnly;

  /// Ranked the same way SmartSearchScreen previewed them — a listing that
  /// misses one criterion but is otherwise close still shows up here,
  /// further down, instead of disappearing outright. See search_relevance.
  List<Listing> get _results {
    final matched = allListings.where((listing) {
      if (keyword.isEmpty) return true;
      final query = keyword.toLowerCase();
      return listing.title.toLowerCase().contains(query) ||
          listing.zone.toLowerCase().contains(query) ||
          listing.agency.name.toLowerCase().contains(query);
    }).map((l) => (listing: l, score: listingRelevance(l, criteria))).where((m) => m.score >= relevanceCutoff).toList();

    switch (sort) {
      case SortOption.relevance:
        matched.sort((a, b) => b.score.compareTo(a.score));
        break;
      case SortOption.newest:
        matched.sort((a, b) => b.listing.createdAt.compareTo(a.listing.createdAt));
        break;
      case SortOption.priceLow:
        matched.sort((a, b) => a.listing.price.compareTo(b.listing.price));
        break;
      case SortOption.priceHigh:
        matched.sort((a, b) => b.listing.price.compareTo(a.listing.price));
        break;
    }
    return matched.map((m) => m.listing).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final results = _results;
    final tags = <String>[
      if (zone != 'هەموو') zone,
      if (purpose != null) _purposeLabel(purpose!),
      if (type != 'all') _typeLabel(type),
      if (rooms != null) rooms == 4 ? 'search.rooms_plus'.tr() : '$rooms ${'listing.rooms'.tr()}',
      if (verifiedOnly) 'search.verified_tag'.tr(),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('search.results_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('search.results_count_subtitle'.tr(args: ['${results.length}']), style: TextStyle(color: palette.textMuted, fontSize: 9.5, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: results.isEmpty
          ? _EmptyResult(onEdit: () => Navigator.pop(context))
          : CustomScrollView(
              slivers: [
                if (tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 7),
                        itemBuilder: (_, index) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(color: palette.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(99), border: Border.all(color: palette.primary.withOpacity(0.22))),
                          child: Text(tags[index], style: TextStyle(color: palette.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
                          (_, index) => ListingCard(listing: results[index], animationIndex: index),
                          childCount: results.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _typeLabel(String value) {
    switch (value) {
      case 'house':
        return 'filters.house'.tr();
      case 'villa':
        return 'filters.villa'.tr();
      case 'land':
        return 'filters.land'.tr();
      case 'shop':
        return 'filters.shop'.tr();
      default:
        return value;
    }
  }

  String _purposeLabel(ListingPurpose value) {
    switch (value) {
      case ListingPurpose.rent:
        return 'filters.rent'.tr();
      case ListingPurpose.installment:
        return 'filters.installment'.tr();
      case ListingPurpose.sale:
        return 'filters.sale'.tr();
    }
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(color: palette.primary.withOpacity(0.10), shape: BoxShape.circle),
              child: Icon(Icons.search_off_rounded, color: palette.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text('search.no_results_found'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('search.no_results_hint'.tr(), textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: onEdit, icon: const Icon(Icons.tune_rounded), label: Text('search.edit_filters'.tr())),
          ],
        ),
      ),
    );
  }
}
