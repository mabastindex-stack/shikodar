import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

class FavoriteRepository {
  final ApiClient _client;
  const FavoriteRepository(this._client);

  /// Returns true if now favorited, false if the toggle removed it.
  Future<bool> toggle({required String type, required String id}) async {
    try {
      final response = await _client.dio.post('/favorites/toggle', data: {'type': type, 'id': id});
      return response.data['favorited'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The signed-in user's favorited listing/project ids, for seeding
  /// [FavoritesStore] — a plain set since callers only need membership.
  Future<Set<String>> fetchIds() async {
    try {
      final response = await _client.dio.get('/favorites');
      final data = response.data as List;
      return data.map((json) => json['favoritable_id'].toString()).toSet();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
