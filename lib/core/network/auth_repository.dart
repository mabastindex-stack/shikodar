import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/user_session.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthResult {
  final AccountRole role;
  final String token;
  final String name;

  /// Null for a client (never has an agency) or if the signed-in business
  /// account's agency somehow failed to load. Lets a business owner's own
  /// public profile page (AgencyProfileScreen/DeveloperProfileScreen) know
  /// it's looking at itself, without hardcoding any particular agency id.
  final String? agencyId;

  /// The business's package tier ('starter'..'enterprise') and contract
  /// expiry — both null for a client. The backend only reveals the
  /// contract fields on login/me (see Agency::$hidden server-side), so
  /// these are the one legitimate place in the app that ever sees them.
  final String? tier;
  final DateTime? contractEndDate;

  const AuthResult({required this.role, required this.token, required this.name, this.agencyId, this.tier, this.contractEndDate});
}

/// Wraps the Laravel API's /auth/* endpoints. Persists the bearer token
/// to SharedPreferences under 'auth_token' — ApiClient's own interceptor
/// reads that same key and attaches it to every subsequent request.
class AuthRepository {
  final ApiClient _client;
  const AuthRepository(this._client);

  /// Registers a new CLIENT account (the only self-service role) and
  /// triggers an OTP send. Returns the dev-only OTP code when no real SMS
  /// gateway is configured server-side, so it can be shown during testing.
  Future<String?> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String zone,
  }) async {
    try {
      final response = await _client.dio.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'zone': zone,
      });
      return response.data['dev_otp_code'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthResult> verifyOtp({required String phone, required String code}) async {
    try {
      final response = await _client.dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'code': code,
      });
      return _saveAuthResult(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String?> resendOtp({required String phone}) async {
    try {
      final response = await _client.dio.post('/auth/resend-otp', data: {'phone': phone});
      return response.data['dev_otp_code'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthResult> login({required String phone, required String password}) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      return _saveAuthResult(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Called once at app startup. If a token was saved from a previous
  /// session, confirms it's still valid via /auth/me and rebuilds the
  /// AuthResult from it; clears the stored token and returns null if the
  /// token is missing, expired, or revoked.
  Future<AuthResult?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;
    try {
      final response = await _client.dio.get('/auth/me');
      final role = _roleFromString(response.data['role'] as String);
      final name = response.data['name'] as String? ?? '';
      final agency = response.data['agency'];
      return AuthResult(
        role: role,
        token: token,
        name: name,
        agencyId: agency?['id']?.toString(),
        tier: agency?['tier'],
        contractEndDate: agency?['contract_end_date'] != null ? DateTime.tryParse(agency['contract_end_date']) : null,
      );
    } on DioException {
      await prefs.remove('auth_token');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException {
      // Best-effort — proceed with the local logout either way.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<AuthResult> _saveAuthResult(dynamic data) async {
    final token = data['token'] as String;
    final role = _roleFromString(data['user']['role'] as String);
    final name = data['user']['name'] as String? ?? '';
    final agency = data['user']['agency'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    return AuthResult(
      role: role,
      token: token,
      name: name,
      agencyId: agency?['id']?.toString(),
      tier: agency?['tier'],
      contractEndDate: agency?['contract_end_date'] != null ? DateTime.tryParse(agency['contract_end_date']) : null,
    );
  }

  AccountRole _roleFromString(String value) => AccountRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => AccountRole.client,
      );
}
