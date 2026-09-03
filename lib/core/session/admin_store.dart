import 'package:flutter/foundation.dart';
import '../mock/mock_data.dart';
import '../models/listing.dart';
import '../../features/offers/screens/offers_list_screen.dart';

/// A business account's package contract terms — collected once by the admin
/// in `CreateAgencyContractScreen`, since agencies/companies/complexes never
/// self-register. Kept separate from `Agency` because contract terms (price,
/// contact info, term dates) are administrative, not part of the business's
/// own public profile.
class Contract {
  final String agencyId;
  final String agencyName;
  final PackageTier tier;
  final String phone;
  final String email;
  final int price;
  final DateTime startDate;
  final DateTime endDate;

  const Contract({
    required this.agencyId,
    required this.agencyName,
    required this.tier,
    required this.phone,
    required this.email,
    required this.price,
    required this.startDate,
    required this.endDate,
  });
}

/// Everything an administrator manages, in one reactive place — separate
/// from `MockData`'s read-mostly seed data, since admin actions (creating an
/// agency, publishing an offer, picking a "top" listing) need to notify every
/// screen that displays them immediately, the same way `BusinessProfileStore`
/// already does for an owner's own profile edits.
///
/// Kept deliberately as three independent lists rather than one big model —
/// per the product rule that package, offer, and home ad-placements are
/// three separate concerns that must never be conflated.
class AdminStore extends ChangeNotifier {
  /// Every business account on the platform. Starts with the two seed
  /// agencies already referenced throughout the app (`MockData.agencyShiko`/
  /// `agencyBasic`) so existing listings/projects keep resolving correctly,
  /// then grows as the admin creates new agency/company/complex accounts.
  final List<Agency> agencies = [MockData.agencyShiko, MockData.agencyBasic];

  /// Contract terms for every business account, one per agency, seeded with
  /// realistic terms for the two launch agencies so the dashboard's
  /// "expiring contracts" list has real data to derive from from day one.
  final List<Contract> contracts = [
    Contract(
      agencyId: MockData.agencyShiko.id,
      agencyName: MockData.agencyShiko.name,
      tier: MockData.agencyShiko.tier,
      phone: '07701234567',
      email: '',
      price: 400,
      startDate: DateTime.now().subtract(const Duration(days: 361)),
      endDate: DateTime.now().add(const Duration(days: 4)),
    ),
    Contract(
      agencyId: MockData.agencyBasic.id,
      agencyName: MockData.agencyBasic.name,
      tier: MockData.agencyBasic.tier,
      phone: '07709876543',
      email: '',
      price: 100,
      startDate: DateTime.now().subtract(const Duration(days: 335)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  /// The real, user-facing promotional offers shown in `OffersListScreen` —
  /// admin-authored from here on, seeded with the original 3 launch offers.
  final List<Offer> offers = List.of(defaultOffers);

  /// Home-feed hero banner photos — a separate paid placement, unrelated to
  /// packages/offers.
  final List<String> heroPhotos = [
    'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=1200&q=85',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=85',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=85',
  ];

  /// Sponsor/partner logos shown in the home feed's scrolling marquee —
  /// local asset paths for the original launch sponsors; new ones added by
  /// admin are network image URLs instead (no way to ship a new local asset
  /// at runtime), so consumers must handle both.
  final List<String> sponsorLogos = [
    'assets/images/logo_mykorek.jpg',
    'assets/images/logo_asiacell.png',
    'assets/images/logo_oneclick.png',
    'assets/images/logo_visicon.png',
    'assets/images/logo_onpoint.png',
    'assets/images/logo_me.jpg',
    'assets/images/logo_apple.jpg',
    'assets/images/logo_uplift.jpg',
  ];

  // --- Agencies -------------------------------------------------------

  void addAgency(Agency agency) {
    agencies.add(agency);
    notifyListeners();
  }

  void updateAgency(Agency updated) {
    final index = agencies.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    agencies[index] = updated;
    // The two seed agencies are also held as their own static fields,
    // referenced directly all over the app (my listings, profile, etc.) —
    // keep those in sync too. Note: a `Listing`/`Project` already created
    // embeds the `Agency` object it had *at creation time*, so pre-existing
    // ones won't retroactively show a tier/verified change here — only
    // id-based comparisons (which is how ownership is checked everywhere)
    // and anything created from now on will see the update.
    if (updated.id == MockData.agencyShiko.id) MockData.agencyShiko = updated;
    if (updated.id == MockData.agencyBasic.id) MockData.agencyBasic = updated;
    notifyListeners();
  }

  void removeAgency(String id) {
    agencies.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  String nextAgencyId() => 'a_${DateTime.now().millisecondsSinceEpoch}';

  void addContract(Contract contract) {
    contracts.add(contract);
    notifyListeners();
  }

  // --- Offers -----------------------------------------------------------

  void addOffer(Offer offer) {
    offers.insert(0, offer);
    notifyListeners();
  }

  void updateOffer(Offer updated) {
    final index = offers.indexWhere((o) => o.id == updated.id);
    if (index == -1) return;
    offers[index] = updated;
    notifyListeners();
  }

  void removeOffer(String id) {
    offers.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  String nextOfferId() => 'o_${DateTime.now().millisecondsSinceEpoch}';

  // --- Home ad placements -------------------------------------------------

  void addHeroPhoto(String url) {
    heroPhotos.add(url);
    notifyListeners();
  }

  void removeHeroPhoto(String url) {
    if (heroPhotos.length <= 1) return; // always keep at least one
    heroPhotos.remove(url);
    notifyListeners();
  }

  void addSponsorLogo(String pathOrUrl) {
    sponsorLogos.add(pathOrUrl);
    notifyListeners();
  }

  void removeSponsorLogo(String pathOrUrl) {
    sponsorLogos.remove(pathOrUrl);
    notifyListeners();
  }

  /// Toggles whether a listing shows in the home feed's "top" section —
  /// a placement admin sells separately from packages/offers, so this is
  /// the only lever that touches `Listing.featured`.
  void setListingFeatured(Listing listing, bool featured) {
    final index = MockData.listings.indexWhere((l) => l.id == listing.id);
    if (index == -1) return;
    MockData.listings[index] = listing.copyWith(featured: featured);
    notifyListeners();
  }
}
