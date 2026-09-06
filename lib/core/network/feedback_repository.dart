import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

class FeedbackRepository {
  final ApiClient _client;
  const FeedbackRepository(this._client);

  Future<void> submit({
    required String type,
    required String message,
    int? rating,
    String? screenshotUrl,
  }) async {
    try {
      await _client.dio.post('/feedback', data: {
        'type': type,
        'message': message,
        if (rating != null && rating > 0) 'rating': rating,
        if (screenshotUrl != null) 'screenshot_url': screenshotUrl,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
