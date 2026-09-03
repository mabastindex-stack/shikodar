import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API client. Base URL is stored in SharedPreferences and editable
/// from the in-app settings screen (gear icon) — mirrors the pattern used in
/// shlon-akhdemak so switching between local AppServ/XAMPP and the Hostinger
/// server never requires a rebuild.
class ApiClient {
  static const _baseUrlKey = 'server_base_url';
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';

  final Dio dio;
  String baseUrl;

  ApiClient._(this.dio, this.baseUrl);

  static Future<ApiClient> create() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;

    final dio = Dio(BaseOptions(
      baseUrl: storedUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    final client = ApiClient._(dio, storedUrl);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Sends the active UI locale so backend can localize validation
        // messages / notification copy.
        final locale = prefs.getString('locale_code') ?? 'ku';
        options.headers['Accept-Language'] = locale;
        handler.next(options);
      },
    ));

    return client;
  }

  Future<void> updateBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
    baseUrl = newUrl;
    dio.options.baseUrl = newUrl;
  }
}
