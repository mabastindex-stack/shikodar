import 'package:dio/dio.dart';

import '../models/review.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ReviewRepository {
  final ApiClient _client;
  const ReviewRepository(this._client);

  Future<List<Review>> fetchForAgency(String agencyId) async {
    try {
      final response = await _client.dio.get('/agencies/$agencyId/reviews');
      final data = response.data['data'] as List;
      return data.map((json) => Review.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// One review per user per agency — resubmitting updates the existing one.
  /// Returns the agency's freshly recomputed `rating`/`review_count` so the
  /// caller can update the header stats without a separate agency refetch.
  Future<({Review review, double? rating, int reviewCount})> submit({
    required String agencyId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _client.dio.post('/agencies/$agencyId/reviews', data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
      return (
        review: Review.fromJson(response.data['review']),
        rating: (response.data['agency']['rating'] as num?)?.toDouble(),
        reviewCount: response.data['agency']['review_count'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
