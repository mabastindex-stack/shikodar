import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_palette.dart';
import '../widgets/listing_card.dart';

/// Shows every listing that matches the type filter the user had active on
/// Home — reached via the "بینینی زیاتر" card after the first page of results.
class AllListingsScreen extends StatelessWidget {
  final String typeFilter;
  const AllListingsScreen({super.key, required this.typeFilter});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = MockData.listings.where((l) => typeFilter == 'all' || l.type.name == typeFilter).toList();
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: Text(
          'home.all_listings_title'.tr(),
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.66),
        itemCount: listings.length,
        itemBuilder: (_, i) => ListingCard(listing: listings[i], animationIndex: i),
      ),
    );
  }
}
