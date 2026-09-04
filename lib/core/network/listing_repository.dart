import 'package:dio/dio.dart';

import '../models/listing.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ListingRepository {
  final ApiClient _client;
  const ListingRepository(this._client);

  /// Public browse — matches ListingController@index's filters.
  Future<List<Listing>> fetchAll({
    String? purpose,
    String? type,
    String? zone,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    bool featuredOnly = false,
  }) async {
    try {
      final response = await _client.dio.get('/listings', queryParameters: {
        if (purpose != null) 'purpose': purpose,
        if (type != null) 'type': type,
        if (zone != null) 'zone': zone,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (rooms != null) 'rooms': rooms,
        if (featuredOnly) 'featured_only': true,
        'per_page': 100,
      });
      final data = response.data['data'] as List;
      return data.map((json) => Listing.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Listing> fetchOne(String id) async {
    try {
      final response = await _client.dio.get('/listings/$id');
      return Listing.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// A business account's own listings.
  Future<List<Listing>> fetchMine() async {
    try {
      final response = await _client.dio.get('/my/listings');
      final data = response.data as List;
      return data.map((json) => Listing.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Listing> create(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/my/listings', data: data);
      return Listing.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Listing> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/my/listings/$id', data: data);
      return Listing.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/my/listings/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
