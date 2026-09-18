/// A single "گەشتی ڤیدیۆیی" (video tour) entry on the home feed — a
/// standalone, admin-curated item (see VideoTourResource in the admin
/// panel), unrelated to Project/agency data.
class VideoTour {
  final int id;
  final String title;
  final String? zone;
  final String? agencyName;
  final String image;
  final String videoUrl;

  const VideoTour({
    required this.id,
    required this.title,
    this.zone,
    this.agencyName,
    required this.image,
    required this.videoUrl,
  });

  factory VideoTour.fromJson(Map<String, dynamic> json) => VideoTour(
        id: json['id'] as int,
        title: json['title'] ?? '',
        zone: json['zone'],
        agencyName: json['agency_name'],
        image: json['image'] ?? '',
        videoUrl: json['video_url'] ?? '',
      );
}
