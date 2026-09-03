import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_palette.dart';
import '../widgets/filter_bar.dart';
import '../widgets/listing_card.dart';

/// Zone names are stored/compared as raw Kurdish (matching `ZoneCardRow`'s
/// data and the shared mock listings), so only the _displayed_ label is
/// localized here — the value passed in from navigation never changes.
String _zoneLabel(String zone) {
  switch (zone) {
    case 'هەموو':
      return 'zones.all'.tr();
    case 'شۆڕجە':
      return 'zones.shorja'.tr();
    case 'ڕاپەرین':
      return 'zones.raparin'.tr();
    case 'ناوەڕاستی شار':
      return 'zones.city_center'.tr();
    case 'ئیمام قاسم':
      return 'zones.imam_qasim'.tr();
    case 'ئازادی':
      return 'zones.azadi'.tr();
    case 'گرناتە':
      return 'zones.granata'.tr();
    default:
      return zone;
  }
}

/// A dedicated page for one Kirkuk zone — its own type/purpose filter at
/// the top, and larger listing cards below, reached by tapping a zone card
/// on Home.
class ZoneDetailScreen extends StatefulWidget {
  final String zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  final _filterState = HomeFilterState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = MockData.listings.where((l) {
      if (widget.zone != 'هەموو' && l.zone != widget.zone) return false;
      if (_filterState.type != 'all' && l.type.name != _filterState.type) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, size: 17, color: palette.gold),
            const SizedBox(width: 6),
            Text(_zoneLabel(widget.zone), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: FilterBar(
              state: _filterState,
              onChanged: () => setState(() {}),
            ),
          ),
          Expanded(
            child: listings.isEmpty
                ? Center(child: Text('zone_detail.no_listings'.tr(), style: TextStyle(color: palette.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => SizedBox(height: 320, child: ListingCard(listing: listings[i], animationIndex: i)),
                  ),
          ),
        ],
      ),
    );
  }
}
