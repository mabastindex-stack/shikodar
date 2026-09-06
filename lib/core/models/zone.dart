class Zone {
  final String id;
  final String name;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  const Zone({required this.id, required this.name, this.imageUrl, this.lat, this.lng});

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        imageUrl: json['image_url'],
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
}
