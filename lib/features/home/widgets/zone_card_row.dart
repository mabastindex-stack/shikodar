import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/zone_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../screens/zone_detail_screen.dart';

class ZoneItem {
  final String name;
  final String? imageUrl;
  const ZoneItem(this.name, this.imageUrl);
}

/// Zone names are stored/compared as raw Kurdish (matches the shared mock
/// data), so only the _displayed_ label is localized here — the underlying
/// `name` value used for selection/navigation never changes.
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

/// "All" is always the first card and never comes from the backend — it's
/// a filter option, not a real neighborhood.
const _allZoneItem = ZoneItem('هەموو', 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=400&q=70');

/// Horizontal scroll of real photo cards for Kirkuk's zones — tapping one
/// opens a dedicated page for that zone (its own filters + listings). The
/// zone list itself (name, order, photo) comes from the admin panel's Zone
/// resource via GET /zones, so adding/renaming/reordering/removing one
/// there is reflected here without an app update.
class ZoneCardRow extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const ZoneCardRow({super.key, required this.selected, required this.onSelect});

  @override
  State<ZoneCardRow> createState() => _ZoneCardRowState();
}

class _ZoneCardRowState extends State<ZoneCardRow> {
  List<ZoneItem> _zoneItems = const [_allZoneItem];

  @override
  void initState() {
    super.initState();
    context.read<ZoneRepository>().fetchAll().then((zones) {
      if (!mounted) return;
      setState(() {
        _zoneItems = [
          _allZoneItem,
          ...zones.map((z) => ZoneItem(z.name, z.imageUrl)),
        ];
      });
    }).catchError((_) {
      // Offline or the server hiccuped — the "All" card alone still lets
      // browsing continue, it just won't offer specific zones this load.
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = widget.selected;
    final onSelect = widget.onSelect;
    return SizedBox(
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _zoneItems.map((z) {
          final isSelected = selected == z.name;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: GestureDetector(
              onTap: () {
                onSelect(z.name);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZoneDetailScreen(zone: z.name)));
              },
              child: AnimatedContainer(
                duration: AppMotion.standard,
                width: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? palette.gold : palette.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow.withOpacity(isSelected ? 0.38 : 0.18),
                      blurRadius: isSelected ? 20 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (z.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: z.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: palette.surfaceElevated),
                        errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                      )
                    else
                      Container(color: palette.surfaceElevated),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(isSelected ? 0.6 : 0.5)],
                        ),
                      ),
                    ),
                    if (isSelected)
                      const PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.goldLight,
                          size: 19,
                        ),
                      ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 10,
                      child: Text(
                        _zoneLabel(z.name),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
