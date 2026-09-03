/// Real Kirkuk city neighbourhoods — name, latitude, longitude, and whether
/// it's one of the handful shown at the widest city zoom.
///
/// Sourced from OpenStreetMap's `place=neighbourhood/suburb` data for
/// Kirkuk (queried via the Overpass API), then cleaned up: exact duplicates
/// merged, private housing-complex brands (مجمع … السكني, "…ستي") dropped
/// since they're developments rather than traditional quarters, and the
/// display name prefers an existing Sorani-script form over a transliterated
/// Latin one wherever OSM tagged both. This is independent of `MockData`'s
/// listing `zone` strings — it exists purely to draw and label the real city
/// on the search map, not to drive the listing filters.
class KirkukNeighborhood {
  const KirkukNeighborhood(this.name, this.lat, this.lng, {this.major = false});

  final String name;
  final double lat;
  final double lng;

  /// Shown at the widest city-wide zoom, before the rest reveal themselves —
  /// a mix of the largest/best-known quarters, spread across the whole city
  /// so the earliest view still reads as "all of Kirkuk", not one corner.
  final bool major;
}

const List<KirkukNeighborhood> kirkukNeighborhoods = [
  KirkukNeighborhood('کۆبانی', 35.3773, 44.3718),
  KirkukNeighborhood('شقق صيادة', 35.3798, 44.334),
  KirkukNeighborhood('حي ٥٥', 35.3896, 44.3988),
  KirkukNeighborhood('حي الزوراء', 35.3905, 44.3884),
  KirkukNeighborhood('حي دوميز', 35.3916, 44.3801),
  KirkukNeighborhood('حي النداء', 35.3953, 44.371),
  KirkukNeighborhood('حي 1 اذار', 35.3967, 44.3618),
  KirkukNeighborhood('دور السكك', 35.3976, 44.3889),
  KirkukNeighborhood('حي العسكري', 35.4011, 44.4041),
  KirkukNeighborhood('حي عسكري ٢', 35.4019, 44.4114),
  KirkukNeighborhood('حي عسكري ١', 35.4051, 44.4041),
  KirkukNeighborhood('حي 1 حزيران', 35.4063, 44.3346),
  KirkukNeighborhood('حي بهار', 35.4064, 44.3698),
  KirkukNeighborhood('شوقەکانی پەنجا عەلی', 35.4082, 44.4311),
  KirkukNeighborhood('اسرى و مفقودين ١', 35.4101, 44.3859),
  KirkukNeighborhood('واحد حزيران', 35.4102, 44.3261),
  KirkukNeighborhood('حي الواسطي', 35.4129, 44.351),
  KirkukNeighborhood('حي القادسية الاولى', 35.4163, 44.4179),
  KirkukNeighborhood('مدينة الامل', 35.4185, 44.3742),
  KirkukNeighborhood('حي رابرين', 35.4188, 44.3892, major: true),
  KirkukNeighborhood('حي السكك', 35.419, 44.3334),
  KirkukNeighborhood('حي الضباط', 35.419, 44.3594),
  KirkukNeighborhood('حي النصر', 35.4237, 44.4002, major: true),
  KirkukNeighborhood('شقق غاز الشمال', 35.4245, 44.3405),
  KirkukNeighborhood('حي العروبة', 35.426, 44.3911),
  KirkukNeighborhood('حي القادسية الثانية', 35.4269, 44.4209),
  KirkukNeighborhood('پەنجا عەلی', 35.4282, 44.4329, major: true),
  KirkukNeighborhood('حي المعلمين', 35.4295, 44.3797, major: true),
  KirkukNeighborhood('حي الخضراء', 35.435, 44.3487),
  KirkukNeighborhood('حي الحجاج', 35.4361, 44.3955),
  KirkukNeighborhood('حي المنصور', 35.4374, 44.3738),
  KirkukNeighborhood('حي الحرية', 35.438, 44.4174),
  KirkukNeighborhood('حي غرناطة', 35.4382, 44.3831, major: true),
  KirkukNeighborhood('حي الوحدة', 35.4418, 44.4021, major: true),
  KirkukNeighborhood('حي تسعين', 35.4434, 44.3673),
  KirkukNeighborhood('حي العلماء', 35.4439, 44.394),
  KirkukNeighborhood('حي سومر', 35.4474, 44.3829),
  KirkukNeighborhood('الممدودة', 35.4475, 44.3948),
  KirkukNeighborhood('ڕوناکی', 35.4479, 44.4029),
  KirkukNeighborhood('گەڕەکی بارزان', 35.448, 44.4069),
  KirkukNeighborhood('حي بختياري', 35.4485, 44.4113),
  KirkukNeighborhood('تسعین', 35.4499, 44.3688, major: true),
  KirkukNeighborhood('لەتیفاوە', 35.4518, 44.4191),
  KirkukNeighborhood('ڕەشیداوە', 35.4521, 44.4135),
  KirkukNeighborhood('شقق القصابخانة', 35.4525, 44.4012),
  KirkukNeighborhood('حي القصابخانه', 35.4527, 44.3944),
  KirkukNeighborhood('حي يسكي باهو', 35.4541, 44.3738),
  KirkukNeighborhood('حي قورية', 35.4551, 44.3672),
  KirkukNeighborhood('حي المصلى', 35.4572, 44.3962),
  KirkukNeighborhood('حي الكورنيش', 35.4576, 44.3863, major: true),
  KirkukNeighborhood('صاري كهية', 35.4591, 44.3738),
  KirkukNeighborhood('قاضي محمد', 35.4604, 44.3958, major: true),
  KirkukNeighborhood('شۆڕجە', 35.4621, 44.4093, major: true),
  KirkukNeighborhood('محلة جقور', 35.4645, 44.3996),
  KirkukNeighborhood('حي الجمهورية', 35.4647, 44.3746, major: true),
  KirkukNeighborhood('محلة بولاق حسين', 35.4696, 44.4036),
  KirkukNeighborhood('محلة شاطرلو', 35.4724, 44.3784),
  KirkukNeighborhood('گەڕەکی ئیمام قاسم', 35.4759, 44.4004, major: true),
  KirkukNeighborhood('گەڕەکی دەروازە', 35.4772, 44.4252, major: true),
  KirkukNeighborhood('حي الماس', 35.4787, 44.3845),
  KirkukNeighborhood('فەیلەق', 35.4798, 44.3621, major: true),
  KirkukNeighborhood('حي أزادي', 35.4812, 44.4071, major: true),
  KirkukNeighborhood('گەڕەکی کوردستان', 35.4837, 44.3615, major: true),
  KirkukNeighborhood('باروتخانە', 35.485, 44.4222, major: true),
  KirkukNeighborhood('تەپە عەبدواڵا', 35.4864, 44.3912),
  KirkukNeighborhood('عەرەفە', 35.4888, 44.3715, major: true),
  KirkukNeighborhood('سرجنار', 35.4919, 44.4022, major: true),
  KirkukNeighborhood('منطقة الصالحي', 35.4952, 44.3391),
  KirkukNeighborhood('حي الاندلس', 35.4968, 44.3889),
  KirkukNeighborhood('ڕەحیاوە', 35.4983, 44.3999, major: true),
  KirkukNeighborhood('گەڕەکی ساڵەیی', 35.4989, 44.3356),
  KirkukNeighborhood('حي العمل الشعبي', 35.504, 44.3256),
  KirkukNeighborhood('سۆنە گۆلی', 35.515, 44.4146),
  KirkukNeighborhood('شۆراو', 35.5237, 44.3905, major: true),
  KirkukNeighborhood('شۆراو عەزیز وەیسی', 35.536, 44.3911),
  KirkukNeighborhood('گورگەچاڵ', 35.5422, 44.3609, major: true),
];
