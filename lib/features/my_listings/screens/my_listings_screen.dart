import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/boost_sheet.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../listing/screens/listing_detail_screen.dart';
import 'create_listing_screen.dart';
import 'edit_listing_screen.dart';

enum _StatusFilter { all, active, sold, draft }

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  _StatusFilter _filter = _StatusFilter.all;

  // Demo: treat the enterprise agency's listings as "my listings".
  List<Listing> get _myListings => MockData.listings.where((l) => l.agency.id == MockData.agencyShiko.id).toList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = _myListings;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.my_listings'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateListingScreen()));
          if (created == true && mounted) setState(() {});
        },
        backgroundColor: palette.textPrimary,
        icon: Icon(Icons.add_rounded, color: palette.background),
        label: Text('my_listings.new_listing_fab'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package usage strip.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text('my_listings.active_count'.tr(args: ['${listings.length}']), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                        child: Text('my_listings.enterprise_badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 14),
                // Status filter tabs.
                Row(
                  children: [
                    Expanded(child: _statusTab(palette, 'filters.all'.tr(), _StatusFilter.all)),
                    const SizedBox(width: 8),
                    Expanded(child: _statusTab(palette, 'my_listings.status_active'.tr(), _StatusFilter.active)),
                    const SizedBox(width: 8),
                    Expanded(child: _statusTab(palette, 'my_listings.status_sold'.tr(), _StatusFilter.sold)),
                    const SizedBox(width: 8),
                    Expanded(child: _statusTab(palette, 'my_listings.status_draft'.tr(), _StatusFilter.draft)),
                  ],
                ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
              ],
            ),
          ),
          Expanded(
            child: listings.isEmpty
                ? Center(child: Text('my_listings.empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _listingRow(palette, listings[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusTab(AppPalette palette, String label, _StatusFilter value) {
    final selected = _filter == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.textPrimary : palette.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _listingRow(AppPalette palette, Listing listing, int index) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing))),
        borderRadius: BorderRadius.circular(18),
        child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 74,
                    height: 74,
                    child: listing.imageUrls.isEmpty
                        ? Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted))
                        : isNetworkImage(listing.imageUrls.first)
                            ? CachedNetworkImage(imageUrl: listing.imageUrls.first, fit: BoxFit.cover)
                            : Image.file(File(listing.imageUrls.first), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700))),
                          _statusBadge(listing),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('\$${listing.price.toStringAsFixed(0)}', style: TextStyle(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 13, color: palette.textSecondary),
                          const SizedBox(width: 3),
                          Text('${(index + 1) * 63}', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                          const SizedBox(width: 12),
                          Icon(Icons.chat_bubble_outline, size: 13, color: palette.textSecondary),
                          const SizedBox(width: 3),
                          Text('${(index + 1) * 4}', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: palette.divider),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(palette, Icons.edit_outlined, 'my_listings.edit_action'.tr(), () async {
                    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => EditListingScreen(listing: listing)));
                    if (saved == true && mounted) setState(() {});
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn(palette, Icons.trending_up_rounded, 'my_listings.boost_action'.tr(), () => showBoostSheet(context, itemName: listing.title))),
                const SizedBox(width: 8),
                _actionIconBtn(Icons.delete_outline_rounded, palette.error, () => _confirmDelete(palette, listing)),
              ],
            ),
          ],
        ),
        ),
      ),
    ).animate(delay: (60 * index).ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _statusBadge(Listing listing) {
    final isSold = listing.purpose == ListingPurpose.sale && listing.featured;
    final label = isSold ? 'my_listings.badge_featured'.tr() : 'my_listings.status_active'.tr();
    final color = isSold ? AppColors.goldDark : AppColors.whatsapp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _actionBtn(AppPalette palette, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: palette.textPrimary),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: palette.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _confirmDelete(AppPalette palette, Listing listing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('my_listings.confirm_delete_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('my_listings.confirm_delete_message'.tr(args: [listing.title]), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              MockData.listings.removeWhere((l) => l.id == listing.id);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('my_listings.delete_action'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
