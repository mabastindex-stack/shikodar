import 'package:dio/dio.dart';

import '../../features/packages/screens/packages_screen.dart';
import 'api_client.dart';
import 'api_exception.dart';

class PackageRepository {
  final ApiClient _client;
  const PackageRepository(this._client);

  Future<List<Package>> fetchAll() async {
    try {
      final response = await _client.dio.get('/packages');
      final data = response.data as List;
      return data.map((json) => Package.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
