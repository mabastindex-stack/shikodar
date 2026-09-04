import 'package:dio/dio.dart';

import '../../features/offers/screens/offers_list_screen.dart';
import 'api_client.dart';
import 'api_exception.dart';

class OfferRepository {
  final ApiClient _client;
  const OfferRepository(this._client);

  Future<List<Offer>> fetchAll() async {
    try {
      final response = await _client.dio.get('/offers');
      final data = response.data as List;
      return data.map((json) => Offer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
