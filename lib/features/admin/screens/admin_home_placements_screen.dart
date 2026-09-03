import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';

/// Home-feed ad placements — hero photos, the sponsor-logo marquee, and
/// "top" (featured) units. Deliberately its own screen, separate from
/// packages and offers: these are sold to businesses as their own
/// placement, not bundled into a subscription tier or a promotional offer.
class AdminHomePlacementsScreen extends StatefulWidget {
  const AdminHomePlacementsScreen({super.key});

  @override
  State<AdminHomePlacementsScreen> createState() => _AdminHomePlacementsScreenState();
}

class _AdminHomePlacementsScreenState extends State<AdminHomePlacementsScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);
  String? _selectedAgencyId;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        automaticallyImplyLeading: false,
        title: Text('admin.home_placements_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: palette.primary,
          unselectedLabelColor: palette.textMuted,
          indicatorColor: palette.primary,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'admin.home_placements_tab_top_units'.tr()),
            Tab(text: 'admin.home_placements_tab_sponsors'.tr()),
            Tab(text: 'admin.home_placements_tab_hero'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _topUnitsTab(palette),
          _sponsorsTab(palette),
          _heroTab(palette),
        ],
      ),
    );
  }

  // --- Tab 1: Top units ---------------------------------------------------

  Widget _topUnitsTab(AppPalette palette) {
    return Consumer<AdminStore>(
      builder: (context, store, _) {
        final agencies = store.agencies;
        if (agencies.isEmpty) return Center(child: Text('admin.home_placements_no_agencies'.tr(), style: TextStyle(color: palette.textSecondary)));
        final selected = agencies.firstWhere((a) => a.id == _selectedAgencyId, orElse: () => agencies.first);
        final listings = MockData.listings.where((l) => l.agency.id == selected.id).toList();
        final featuredCount = MockData.listings.where((l) => l.featured).length;
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: palette.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('admin.home_placements_featured_banner'.tr(args: ['$featuredCount']), style: TextStyle(color: palette.textPrimary, fontSize: 11.5))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('admin.home_placements_step1_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: agencies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = agencies[i];
                  final isSelected = a.id == selected.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAgencyId = a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? palette.primary : palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(a.name, style: TextStyle(color: isSelected ? palette.onPrimary : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('admin.home_placements_step2_label'.tr(args: [selected.name]), style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: listings.isEmpty
                  ? Center(child: Text('admin.home_placements_no_listings_for_agency'.tr(), style: TextStyle(color: palette.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: listings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _topUnitRow(palette, listings[i], store),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _topUnitRow(AppPalette palette, Listing listing, AdminStore store) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: listing.featured ? Border.all(color: AppColors.gold, width: 1.4) : null,
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: listing.imageUrls.isEmpty
                  ? Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted))
                  : isNetworkImage(listing.imageUrls.first)
                      ? CachedNetworkImage(imageUrl: listing.imageUrls.first, fit: BoxFit.cover)
                      : Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text('\$${listing.price.toStringAsFixed(0)} · ${listing.zone}', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => store.setListingFeatured(listing, !listing.featured),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: listing.featured ? AppColors.gold : palette.surfaceElevated, shape: BoxShape.circle),
              child: Icon(listing.featured ? Icons.star_rounded : Icons.star_border_rounded, size: 19, color: listing.featured ? AppColors.ink : palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Sponsors ------------------------------------------------

  Widget _sponsorsTab(AppPalette palette) {
    return Consumer<AdminStore>(
      builder: (context, store, _) {
        return Column(
          children: [
            Expanded(
              child: store.sponsorLogos.isEmpty
                  ? Center(child: Text('admin.home_placements_no_sponsors'.tr(), style: TextStyle(color: palette.textSecondary)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: store.sponsorLogos.length,
                      itemBuilder: (_, i) {
                        final path = store.sponsorLogos[i];
                        return Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                              child: isNetworkImage(path) ? CachedNetworkImage(imageUrl: path, fit: BoxFit.contain) : Image.asset(path, fit: BoxFit.contain),
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: GestureDetector(
                                onTap: () => store.removeSponsorLogo(path),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(color: palette.error, shape: BoxShape.circle, border: Border.all(color: palette.surface, width: 1.5)),
                                  child: const Icon(Icons.close_rounded, size: 11, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAgencyAsSponsor(context, store),
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: Text('admin.home_placements_add_agency_sponsor_button'.tr()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addCustomLogo(context, store),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text('admin.home_placements_add_custom_logo_button'.tr()),
                      style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickAgencyAsSponsor(BuildContext context, AdminStore store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetPalette = sheetContext.palette;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: sheetPalette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('admin.home_placements_pick_agency_sponsor_title'.tr(), style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ...store.agencies.map((a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.storefront_rounded, color: sheetPalette.primary),
                    title: Text(a.name, style: TextStyle(color: sheetPalette.textPrimary, fontWeight: FontWeight.w600)),
                    onTap: () {
                      final logo = a.logoUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(a.name)}&background=0E554A&color=fff';
                      store.addSponsorLogo(logo);
                      Navigator.pop(sheetContext);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _addCustomLogo(BuildContext context, AdminStore store) {
    final controller = TextEditingController();
    final palette = context.palette;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('admin.home_placements_sponsor_url_dialog_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'admin.url_hint'.tr())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) store.addSponsorLogo(controller.text.trim());
              Navigator.pop(dialogContext);
            },
            child: Text('my_listings.add_photo'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Hero photos -----------------------------------------------

  Widget _heroTab(AppPalette palette) {
    return Consumer<AdminStore>(
      builder: (context, store, _) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: palette.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('admin.home_placements_hero_banner'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 11.5))),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: store.heroPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final url = store.heroPhotos[i];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(width: 60, height: 44, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textSecondary, fontSize: 10.5))),
                        IconButton(onPressed: () => store.removeHeroPhoto(url), icon: Icon(Icons.delete_outline_rounded, color: palette.error, size: 19)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addHeroPhoto(context, store),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text('admin.home_placements_add_hero_photo_button'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addHeroPhoto(BuildContext context, AdminStore store) {
    final controller = TextEditingController();
    final palette = context.palette;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('admin.home_placements_hero_url_dialog_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'admin.url_hint'.tr())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) store.addHeroPhoto(controller.text.trim());
              Navigator.pop(dialogContext);
            },
            child: Text('my_listings.add_photo'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
