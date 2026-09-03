import '../mock/mock_data.dart';
import 'listing.dart';

enum ProjectStatus { underConstruction, completed }

class UnitType {
  final String name;
  final double priceFrom;
  final String area;
  final List<String> images;
  final String description;
  final ListingType type;
  final ListingPurpose purpose;
  const UnitType({
    required this.name,
    required this.priceFrom,
    required this.area,
    required this.images,
    required this.description,
    required this.type,
    required this.purpose,
  });
}

class Project {
  final String id;
  final String name;
  final String zone;
  final List<String> images; // 3 photos — the project's visual identity
  final String videoUrl;
  final double priceFrom;
  final double priceTo;
  final ProjectStatus status;
  final String description;
  final List<String> highlights;
  final List<String> amenities;
  final List<UnitType> unitTypes;
  final String agencyName;
  final Agency agency;
  final String paymentPlan;
  final String completionInfo;
  final List<(String, String)> specs; // (label, value)
  const Project({
    required this.id,
    required this.name,
    required this.zone,
    required this.images,
    required this.videoUrl,
    required this.priceFrom,
    required this.priceTo,
    required this.status,
    required this.description,
    required this.highlights,
    required this.amenities,
    required this.unitTypes,
    required this.agencyName,
    required this.agency,
    required this.paymentPlan,
    required this.completionInfo,
    required this.specs,
  });

  Project copyWith({String? name, String? zone, double? priceFrom, double? priceTo, String? description}) => Project(
        id: id,
        name: name ?? this.name,
        zone: zone ?? this.zone,
        images: images,
        videoUrl: videoUrl,
        priceFrom: priceFrom ?? this.priceFrom,
        priceTo: priceTo ?? this.priceTo,
        status: status,
        description: description ?? this.description,
        highlights: highlights,
        amenities: amenities,
        unitTypes: unitTypes,
        agencyName: agencyName,
        agency: agency,
        paymentPlan: paymentPlan,
        completionInfo: completionInfo,
        specs: specs,
      );
}

final List<Project> mockProjects = [
  Project(
    id: 'p1',
    name: 'گەلی زیبار',
    zone: 'شۆڕجە',
    images: const [
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=900&q=80',
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=900&q=80',
      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=900&q=80',
    ],
    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-modern-house-with-a-swimming-pool-4835-large.mp4',
    priceFrom: 65000,
    priceTo: 140000,
    status: ProjectStatus.underConstruction,
    description: 'پڕۆژەی گەلی زیبار یەکێکە لە گەورەترین پڕۆژە سکنیەکانی کەرکوک.',
    highlights: [
      'پێکهاتووە لە ٤ بلۆکی نیشتەجێبوون بە دیزاینی مۆدێرن',
      'سیستەمی پاراستنی ٢٤ کاتژمێری چالاکە',
      'بۆشایی سەوزی فراوان و پارکی گشتی',
      'نزیکە لە قوتابخانە و بازاڕی گەورە',
    ],
    amenities: ['پارکی گشتی', 'یاریگای منداڵان', 'سیستەمی پاراستن', 'ژینراتەری هاوبەش', 'مزگەوت'],
    unitTypes: [
      UnitType(
        name: 'شوقەی ٢ ژووری',
        priceFrom: 65000,
        area: '110 م²',
        type: ListingType.house,
        purpose: ListingPurpose.sale,
        images: const [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=900&q=80',
          'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=900&q=80',
        ],
        description: 'یەکەیەکی جوان و ڕاحەت گونجاو بۆ خێزانی بچووک، بە دیزاینی کراوە و ڕووناکی سروشتی زۆر، لەگەڵ ئاشپەزخانەیەکی مۆدێرن و بەلکۆنی تایبەت.',
      ),
      UnitType(
        name: 'شوقەی ٣ ژووری',
        priceFrom: 95000,
        area: '145 م²',
        type: ListingType.house,
        purpose: ListingPurpose.sale,
        images: const [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900&q=80',
          'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=900&q=80',
        ],
        description: 'یەکەیەکی فراوانتر گونجاو بۆ خێزانی مامناوەند، سێ ژووری نووستن، دوو حەمام، و ژووری میوان جیاواز لە ژووری نانخواردن.',
      ),
      UnitType(
        name: 'دووبلێکسی گەورە',
        priceFrom: 140000,
        area: '220 م²',
        type: ListingType.villa,
        purpose: ListingPurpose.sale,
        images: const [
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=900&q=80',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=900&q=80',
        ],
        description: 'دووبلێکسی شکۆدار بە دوو نهۆم، حەوشەی تایبەت، و گاراجی ماشین — باشترین هەڵبژاردن بۆ خێزانی گەورە کە حەز بە شوێنی زیاتر دەکەن.',
      ),
      UnitType(
        name: 'شوقەی کرێی مۆبلیا',
        priceFrom: 450,
        area: '95 م²',
        type: ListingType.house,
        purpose: ListingPurpose.rent,
        images: const [
          'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=900&q=80',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=900&q=80',
        ],
        description: 'شوقەیەکی تەواو مۆبلیاکراو ئامادە بۆ کرێی مانگانە، گونجاو بۆ خێزانی نوێی کۆچبەر یان فەرمانبەران.',
      ),
    ],
    agencyName: 'کۆمپانیای شکۆ',
    agency: MockData.agencyShiko,
    paymentPlan: '٪٣٠ پێشەکی + ٣٦ قیستی مانگانە بەبێ زیادە',
    completionInfo: 'چاوەڕوانکراوە تەواو بێت — مارسی ٢٠٢٦',
    specs: [
      ('ژمارەی بلۆک', '٤ بلۆک'),
      ('ژمارەی نهۆم', '٦ نهۆم بۆ هەر بلۆک'),
      ('ڕووبەری گشتی', '١٢,٠٠٠ م²'),
      ('پارکینگ', 'هەر یەکەیەک ١ شوێن'),
    ],
  ),
  Project(
    id: 'p2',
    name: 'شاری ئاسوودە',
    zone: 'ناوەڕاستی شار',
    images: const [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=900&q=80',
      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=900&q=80',
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=900&q=80',
    ],
    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-modern-house-with-a-swimming-pool-4835-large.mp4',
    priceFrom: 88000,
    priceTo: 210000,
    status: ProjectStatus.completed,
    description: 'پڕۆژەی شاری ئاسوودە بە تەواوی تەواو بووە و ئامادەیە بۆ نیشتەجێبوون.',
    highlights: [
      'تایبەتمەندی هۆتێلێکی بچووک لەناو پڕۆژەکەدا',
      'تاوەری کاسبی و پارکینگی ژێرزەوی',
      'هەموو یەکەکان ئامادەن بۆ نیشتەجێبوونی ڕاستەوخۆ',
    ],
    amenities: ['مەلەوانگە', 'یانەی وەرزشی', 'پارکینگی ژێرزەوی', 'سیستەمی پاراستن', 'ماڵپەڕی کۆمەڵگا'],
    unitTypes: [
      UnitType(
        name: 'شوقەی ٢ ژووری',
        priceFrom: 88000,
        area: '125 م²',
        type: ListingType.house,
        purpose: ListingPurpose.sale,
        images: const [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=900&q=80',
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900&q=80',
        ],
        description: 'یەکەیەکی تەواوبووی ئامادە بۆ نیشتەجێبوونی ڕاستەوخۆ، لەگەڵ کارەبا و ئاوی خۆکار وئامادەبوونی تەواوی چاکردنەکان.',
      ),
      UnitType(
        name: 'ڤیلای ڕیزراو',
        priceFrom: 210000,
        area: '300 م²',
        type: ListingType.villa,
        purpose: ListingPurpose.sale,
        images: const [
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=900&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=900&q=80',
        ],
        description: 'ڤیلایەکی شکۆدار بە حەوشەی تایبەت و گاراجی دوو ماشین، لە ڕیزێکی هێمن و پارێزراو لەناو پڕۆژەکەدا.',
      ),
      UnitType(
        name: 'دووکانی بازرگانی',
        priceFrom: 350,
        area: '38 م²',
        type: ListingType.shop,
        purpose: ListingPurpose.rent,
        images: const [
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=900&q=80',
          'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=900&q=80',
        ],
        description: 'دووکانێکی بازرگانی لە تاوەری سەرەکی پڕۆژەکە، نمایشگای گەورە و پیاسەی زۆر لای پێش، گونجاو بۆ هەر بزنسێکی بچووک.',
      ),
    ],
    agencyName: 'کۆمپانیای شکۆ',
    agency: MockData.agencyShiko,
    paymentPlan: 'نەقدی یان ١٨ قیستی مانگانە',
    completionInfo: 'تەواوبووە — ئامادەیە بۆ گواستنەوەی ڕاستەوخۆ',
    specs: [
      ('ژمارەی بلۆک', '٦ بلۆک'),
      ('تاوەری کاسبی', '١ تاوەری ١٢ نهۆمی'),
      ('ڕووبەری گشتی', '٢٠,٠٠٠ م²'),
      ('پارکینگ', 'ژێرزەوی، ٢ شوێن بۆ هەر یەکە'),
    ],
  ),
];
