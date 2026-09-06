import 'package:flutter/material.dart';

import '../../core/models/zone.dart';
import '../../core/theme/app_palette.dart';

/// The one zone picker used by every "publish a listing/project" flow —
/// always the same admin-managed list (`ZoneRepository`) that drives the
/// home zone cards and every zone filter, so whatever a business picks here
/// is guaranteed to match those everywhere else. Previously each create
/// screen picked from a separate, purely-decorative list of ~76 OSM
/// neighbourhoods used only to draw the search map's citywide layer — a
/// name picked there almost never matched an admin zone name, so the
/// listing silently dropped out of every zone-based filter and out of the
/// map's zoomed-in pin view. Reusing one list for both here fixes that at
/// the source instead of just for one screen.
Future<Zone?> pickZoneSheet(
  BuildContext context,
  List<Zone> zones, {
  required String title,
  required String searchHint,
  required String notFoundText,
}) {
  return showModalBottomSheet<Zone>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      var query = '';
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final sheetPalette = context.palette;
          final filtered = query.trim().isEmpty ? zones : zones.where((z) => z.name.contains(query.trim())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(color: sheetPalette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: sheetPalette.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(title, style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setSheetState(() => query = v),
                    style: TextStyle(color: sheetPalette.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: TextStyle(color: sheetPalette.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: sheetPalette.textMuted, size: 20),
                      filled: true,
                      fillColor: sheetPalette.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text(notFoundText, style: TextStyle(color: sheetPalette.textSecondary)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: sheetPalette.divider),
                            itemBuilder: (_, i) {
                              final z = filtered[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.location_on_outlined, color: sheetPalette.primary, size: 20),
                                title: Text(z.name, style: TextStyle(color: sheetPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                onTap: () => Navigator.pop(sheetContext, z),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
