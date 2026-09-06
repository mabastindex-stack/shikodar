import 'package:dio/dio.dart';

import '../models/app_notification.dart';
import 'api_client.dart';
import 'api_exception.dart';

class NotificationRepository {
  final ApiClient _client;
  const NotificationRepository(this._client);

  Future<List<AppNotification>> fetchAll() async {
    try {
      final response = await _client.dio.get('/notifications');
      final data = response.data as List;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead() async {
    try {
      await _client.dio.post('/notifications/mark-read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
