import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'api_client.dart';

/// Registers this device's FCM token against the signed-in user so a
/// broadcast notification can reach their phone even when the app is
/// closed. Called once right after login/session-restore; re-sends
/// automatically if Firebase ever rotates the token underneath us.
///
/// Mobile-only — Firebase isn't initialized on web (see main.dart), so
/// this is a no-op there rather than every login-flow call site needing
/// its own kIsWeb check.
class PushRepository {
  final ApiClient _client;
  const PushRepository(this._client);

  Future<void> registerDevice() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _sendToken(token);

      messaging.onTokenRefresh.listen(_sendToken);
    } catch (_) {
      // Best-effort — a user without push permission (or on a platform/
      // emulator without Play Services) should never be blocked by this.
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await _client.dio.post('/device-token', data: {'token': token});
    } catch (_) {
      // Retried naturally on next app open / token refresh.
    }
  }
}
