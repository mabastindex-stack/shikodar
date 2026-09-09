enum ListingPurpose { rent, sale, installment }

enum ListingType { house, villa, land, shop }

enum PackageTier { starter, basic, business, premium, enterprise }

extension PackageTierX on PackageTier {
  String get label {
    switch (this) {
      case PackageTier.starter:
        return 'Starter';
      case PackageTier.basic:
        return 'Basic';
      case PackageTier.business:
        return 'Business';
      case PackageTier.premium:
        return 'Premium';
      case PackageTier.enterprise:
        return 'Enterprise';
    }
  }
}

class Agency {
  final String id;
  final String name;
  final String? logoUrl;
  final PackageTier tier;
  final bool verified;
  final double? rating;
  final int reviewCount;
  final int yearsActive;
  final int dealsCompleted;
  final int responseRatePercent;
  final List<String> specialties;
  final List<String> serviceAreas;
  final String bio;

  /// The business's own public contact — how a browsing user reaches it
  /// directly (profile page, or any project/unit without its own
  /// listing-level phone/whatsapp). Null until the business sets one.
  final String? phone;
  final String? whatsapp;

  const Agency({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.tier,
    this.verified = false,
    this.rating,
    this.reviewCount = 0,
    this.yearsActive = 0,
    this.dealsCompleted = 0,
    this.responseRatePercent = 0,
    this.specialties = const [],
    this.serviceAreas = const [],
    this.bio = '',
    this.phone,
    this.whatsapp,
  });

  Agency copyWith({
    String? name,
    String? logoUrl,
    PackageTier? tier,
    bool? verified,
    double? rating,
    int? reviewCount,
    int? yearsActive,
    int? dealsCompleted,
    int? responseRatePercent,
    List<String>? specialties,
    List<String>? serviceAreas,
    String? bio,
  }) =>
      Agency(
        id: id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        tier: tier ?? this.tier,
        verified: verified ?? this.verified,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        yearsActive: yearsActive ?? this.yearsActive,
        dealsCompleted: dealsCompleted ?? this.dealsCompleted,
        responseRatePercent: responseRatePercent ?? this.responseRatePercent,
        specialties: specialties ?? this.specialties,
        serviceAreas: serviceAreas ?? this.serviceAreas,
        bio: bio ?? this.bio,
      );

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        logoUrl: json['logo_url'],
        tier: PackageTier.values.firstWhere(
          (t) => t.name == (json['tier'] ?? 'starter'),
          orElse: () => PackageTier.starter,
        ),
        verified: json['verified'] ?? false,
        rating: (json['rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] ?? 0,
        yearsActive: json['years_active'] ?? 0,
        dealsCompleted: json['deals_completed'] ?? 0,
        responseRatePercent: json['response_rate_percent'] ?? 0,
        specialties: (json['specialties'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        serviceAreas: (json['service_areas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        bio: json['bio'] ?? '',
        phone: json['phone'],
        whatsapp: json['whatsapp'],
      );
}

class Listing {
  final String id;
  final String title;
  final String zone; // neighborhood within Kirkuk
  final ListingPurpose purpose;
  final ListingType type;
  final double price;
  final bool negotiable;
  final double? priceLow;
  final double? priceHigh;
  final double? downPayment;
  final double? monthlyInstallment;
  final int? installmentMonths;
  final List<String> imageUrls;
  final String? videoUrl;
  final double? areaSqm;
  final int? rooms;
  final double? lat;
  final double? lng;
  final Agency agency;
  final bool featured;
  final DateTime createdAt;
  final String description;
  final String? phone;
  final String? whatsapp;

  const Listing({
    required this.id,
    required this.title,
    required this.zone,
    required this.purpose,
    required this.type,
    required this.price,
    this.negotiable = false,
    this.priceLow,
    this.priceHigh,
    this.downPayment,
    this.monthlyInstallment,
    this.installmentMonths,
    this.imageUrls = const [],
    this.videoUrl,
    this.areaSqm,
    this.rooms,
    this.lat,
    this.lng,
    required this.agency,
    this.featured = false,
    required this.createdAt,
    this.description = '',
    this.phone,
    this.whatsapp,
  });

  Listing copyWith({
    String? title,
    double? price,
    String? zone,
    bool? negotiable,
    String? description,
    String? phone,
    String? whatsapp,
    bool? featured,
  }) =>
      Listing(
        id: id,
        title: title ?? this.title,
        zone: zone ?? this.zone,
        purpose: purpose,
        type: type,
        price: price ?? this.price,
        negotiable: negotiable ?? this.negotiable,
        priceLow: priceLow,
        priceHigh: priceHigh,
        downPayment: downPayment,
        monthlyInstallment: monthlyInstallment,
        installmentMonths: installmentMonths,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        areaSqm: areaSqm,
        rooms: rooms,
        lat: lat,
        lng: lng,
        agency: agency,
        featured: featured ?? this.featured,
        createdAt: createdAt,
        description: description ?? this.description,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
      );

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        zone: json['zone'] ?? '',
        purpose: ListingPurpose.values.firstWhere(
          (p) => p.name == json['purpose'],
          orElse: () => ListingPurpose.rent,
        ),
        type: ListingType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ListingType.house,
        ),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        negotiable: json['negotiable'] ?? false,
        priceLow: (json['price_low'] as num?)?.toDouble(),
        priceHigh: (json['price_high'] as num?)?.toDouble(),
        downPayment: (json['down_payment'] as num?)?.toDouble(),
        monthlyInstallment: (json['monthly_installment'] as num?)?.toDouble(),
        installmentMonths: json['installment_months'],
        imageUrls: (json['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
        videoUrl: json['video_url'],
        areaSqm: (json['area_sqm'] as num?)?.toDouble(),
        rooms: json['rooms'],
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        agency: Agency.fromJson(json['agency'] ?? const {}),
        featured: json['featured'] ?? false,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        description: json['description'] ?? '',
        phone: json['phone'],
        whatsapp: json['whatsapp'],
      );
}

class Reel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final Agency agency;
  final Listing? listing;
  final double price;
  final Duration duration;
  final int viewsCount;

  const Reel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.agency,
    this.listing,
    required this.price,
    required this.duration,
    this.viewsCount = 0,
  });

  factory Reel.fromJson(Map<String, dynamic> json) => Reel(
        id: json['id'].toString(),
        videoUrl: json['video_url'] ?? '',
        thumbnailUrl: json['thumbnail_url'] ?? '',
        agency: Agency.fromJson(json['agency'] ?? const {}),
        listing: json['listing'] != null ? Listing.fromJson(json['listing']) : null,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        duration: Duration(seconds: json['duration_seconds'] ?? 0),
        viewsCount: json['views_count'] ?? 0,
      );
}
