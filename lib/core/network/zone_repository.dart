import 'package:dio/dio.dart';

import '../models/zone.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Kirkuk neighborhoods managed from the admin panel — reads are public;
/// only the web admin panel can add, rename, reorder, or remove one.
class ZoneRepository {
  final ApiClient _client;
  const ZoneRepository(this._client);

  Future<List<Zone>> fetchAll() async {
    try {
      final response = await _client.dio.get('/zones');
      final data = response.data as List;
      return data.map((json) => Zone.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
