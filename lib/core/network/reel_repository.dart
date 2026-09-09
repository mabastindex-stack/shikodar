import 'package:dio/dio.dart';

import '../models/listing.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ReelRepository {
  final ApiClient _client;
  const ReelRepository(this._client);

  Future<List<Reel>> fetchAll() async {
    try {
      final response = await _client.dio.get('/reels');
      final data = response.data as List;
      return data.map((json) => Reel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Reel>> fetchMine() async {
    try {
      final response = await _client.dio.get('/my/reels');
      final data = response.data as List;
      return data.map((json) => Reel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Reel> create({required String videoUrl, required double price, String? thumbnailUrl, int? durationSeconds}) async {
    try {
      final response = await _client.dio.post('/my/reels', data: {
        'video_url': videoUrl,
        'price': price,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      });
      return Reel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Reel> update(String id, {String? videoUrl, double? price, String? thumbnailUrl, int? durationSeconds}) async {
    try {
      final response = await _client.dio.put('/my/reels/$id', data: {
        if (videoUrl != null) 'video_url': videoUrl,
        if (price != null) 'price': price,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      });
      return Reel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/my/reels/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
