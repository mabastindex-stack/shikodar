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
}
