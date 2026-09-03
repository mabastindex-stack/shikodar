import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_palette.dart';
import '../widgets/listing_card.dart';

/// Global favorites store — a simple ValueNotifier<Set<String>> mirrors the
/// pattern already used for cross-screen favorites sync in shlon-akhdemak.
class FavoritesStore {
  static final ValueNotifier<Set<String>> ids = ValueNotifier({});

  static void toggle(String listingId) {
    final next = Set<String>.from(ids.value);
    next.contains(listingId) ? next.remove(listingId) : next.add(listingId);
    ids.value = next;
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('nav.favorites'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesStore.ids,
                builder: (_, ids, __) {
                  final favs = MockData.listings.where((l) => ids.contains(l.id)).toList();
                  if (favs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: palette.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_border_rounded, color: palette.textMuted, size: 28),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'common.no_results'.tr(),
                            style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: favs.length,
                    itemBuilder: (_, i) => ListingCard(listing: favs[i], animationIndex: i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
