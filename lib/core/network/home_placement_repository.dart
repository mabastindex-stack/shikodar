import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// The home feed's admin-curated placements — hero banner photos and
/// sponsor/partner logos. Reads are public; only the (future, web-only)
/// admin panel can add or remove them.
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
}
