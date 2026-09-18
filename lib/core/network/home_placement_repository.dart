import 'package:dio/dio.dart';

import '../models/video_tour.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// The home feed's admin-curated placements — hero banner photos,
/// sponsor/partner logos, and video tour entries. Reads are public; only
/// the web admin panel can add or remove them.
class HomePlacementRepository {
  final ApiClient _client;
  const HomePlacementRepository(this._client);

  Future<List<String>> fetchHeroPhotos() async {
    try {
      final response = await _client.dio.get('/hero-photos');
      final data = response.data as List;
      return data.map((json) => json['url'] as String).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<String>> fetchSponsorLogos() async {
    try {
      final response = await _client.dio.get('/sponsor-logos');
      final data = response.data as List;
      return data.map((json) => json['url'] as String).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<VideoTour>> fetchVideoTours() async {
    try {
      final response = await _client.dio.get('/video-tours');
      final data = response.data as List;
      return data.map((json) => VideoTour.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
