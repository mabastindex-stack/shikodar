import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// One row from GET /favorites — [type] is 'listing', 'project', or
/// 'agency' (the backend derives it from the polymorphic favoritable_type
/// column), and [data] is that record's own raw JSON, ready to hand to
/// Listing.fromJson/Project.fromJson/Agency.fromJson.
class FavoriteEntry {
  final String type;
  final String id;
  final Map<String, dynamic> data;
  const FavoriteEntry({required this.type, required this.id, required this.data});
}

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

  /// The signed-in user's favorited listing/project/agency ids, for seeding
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

  /// The full favorited records (not just ids) — used by FavoritesScreen to
  /// show favorited accounts and posts without a separate fetch-everything-
  /// and-filter pass over every listing/project/agency in the app.
  Future<List<FavoriteEntry>> fetchAll() async {
    try {
      final response = await _client.dio.get('/favorites');
      final data = response.data as List;
      return data
          .map((json) {
            final favoritable = json['favoritable'];
            if (favoritable is! Map) return null;
            return FavoriteEntry(
              type: json['type']?.toString() ?? 'unknown',
              id: json['favoritable_id'].toString(),
              data: favoritable.cast<String, dynamic>(),
            );
          })
          .whereType<FavoriteEntry>()
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
