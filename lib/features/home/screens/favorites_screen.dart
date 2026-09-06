import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/network/favorite_repository.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/theme/app_palette.dart';
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
  List<Listing> _allListings = [];

  @override
  void initState() {
    super.initState();
    context.read<ListingRepository>().fetchAll().then((listings) {
      if (mounted) setState(() => _allListings = listings);
    });
    FavoritesStore.loadFromServer(context.read<FavoriteRepository>());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesStore.ids,
                builder: (_, ids, __) {
                  final favs = _allListings.where((l) => ids.contains(l.id)).toList();
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
