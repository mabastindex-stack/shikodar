import 'package:dio/dio.dart';

import '../models/dashboard_stats.dart';
import 'api_client.dart';
import 'api_exception.dart';

class DashboardRepository {
  final ApiClient _client;
  const DashboardRepository(this._client);

  Future<DashboardStats> fetchStats() async {
    try {
      final response = await _client.dio.get('/my/dashboard');
      return DashboardStats.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
