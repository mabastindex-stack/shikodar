import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API client. Base URL is stored in SharedPreferences and editable
/// from the in-app settings screen (gear icon) — but that screen only
/// exists in debug/profile builds (see login_screen.dart/settings_screen.dart),
/// so a real published build always talks to the real backend below and a
/// regular user has no way to point the app anywhere else.
class ApiClient {
  static const _baseUrlKey = 'server_base_url';
  static const String defaultBaseUrl = kReleaseMode
      ? 'https://dublinclass.com/api'
      : 'http://127.0.0.1:8000/api';

  final Dio dio;
  String baseUrl;

  ApiClient._(this.dio, this.baseUrl);

  static Future<ApiClient> create() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;

    final dio = Dio(BaseOptions(
      baseUrl: storedUrl,
      // Generous enough for a slow/congested mobile connection to a
      // shared-hosting server — 15s was cutting off requests that a
      // browser (with its own longer patience) still completed fine.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
