import 'package:flutter/material.dart';

import '../../core/models/listing.dart';

/// The set of criteria a search screen collects — shared between
/// SmartSearchScreen (where the visitor sets them) and SearchResultsScreen
/// (where they're applied and ranked), so the two never drift apart.
class SearchCriteria {
  const SearchCriteria({
    this.zone = 'هەموو',
    this.purpose,
    this.type = 'all',
    required this.priceRange,
    required this.areaRange,
    this.rooms,
    this.verifiedOnly = false,
  });

  final String zone;
  final ListingPurpose? purpose;
  final String type;
  final RangeValues priceRange;
  final RangeValues areaRange;
  final int? rooms;
  final bool verifiedOnly;
}

/// A near miss on one range still counts for something — the further
/// outside [range] a value lands, the more its score fades, instead of
/// being excluded outright the moment it crosses the edge.
double _rangeScore(double value, RangeValues range) {
  if (value >= range.start && value <= range.end) return 1.0;
  final span = range.end - range.start;
  if (span <= 0) return 0.4;
  final distance = value < range.start ? range.start - value : value - range.end;
  final ratio = (distance / span).clamp(0.0, 1.0);
  return (1.0 - ratio) * 0.75;
}

/// How well a listing matches the visitor's chosen criteria, from 0 (no
/// relation at all) to 1 (matches every criterion exactly). Unset criteria
/// (zone "هەموو", purpose "any", type "all", rooms unset) don't count for
/// or against a listing — only what the visitor actually chose narrows the
/// score. A listing that misses one criterion but matches the rest still
/// scores reasonably, so a close match shows up (ranked lower) instead of
/// disappearing the moment a single filter isn't a perfect fit.
double listingRelevance(Listing listing, SearchCriteria c) {
  final scores = <double>[];
  if (c.zone != 'هەموو') scores.add(listing.zone == c.zone ? 1.0 : 0.35);
  if (c.purpose != null) scores.add(listing.purpose == c.purpose ? 1.0 : 0.3);
  if (c.type != 'all') scores.add(listing.type.name == c.type ? 1.0 : 0.3);
  scores.add(_rangeScore(listing.price, c.priceRange));
  if (listing.areaSqm != null) scores.add(_rangeScore(listing.areaSqm!, c.areaRange));
  if (c.rooms != null) {
    final r = listing.rooms;
    if (r == null) {
      scores.add(0.4);
    } else if (c.rooms == 4) {
      scores.add(r >= 4 ? 1.0 : (1.0 - (4 - r) * 0.25).clamp(0.0, 1.0));
    } else {
      final diff = (r - c.rooms!).abs();
      scores.add(diff == 0 ? 1.0 : (1.0 - diff * 0.3).clamp(0.0, 1.0));
    }
  }
  if (c.verifiedOnly) scores.add(listing.agency.verified ? 1.0 : 0.5);
  if (scores.isEmpty) return 1.0;
  return scores.reduce((a, b) => a + b) / scores.length;
}

/// Below this, a listing barely relates to what was asked for — worth
/// dropping instead of padding out results with noise.
const relevanceCutoff = 0.3;
