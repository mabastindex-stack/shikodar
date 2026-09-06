import 'api_client.dart';

/// Reports listing/project view and contact-button taps for the business
/// dashboard's real stats — fire-and-forget, since a tracking call
/// shouldn't ever block or interrupt what the user is actually doing.
class ActivityRepository {
  final ApiClient _client;
  const ActivityRepository(this._client);

  void recordView({required String type, required String id}) => _record('/activity/view', type, id);

  void recordContact({required String type, required String id}) => _record('/activity/contact', type, id);

  Future<void> _record(String path, String type, String id) async {
    try {
      await _client.dio.post(path, data: {'type': type, 'id': id});
    } catch (_) {
      // Tracking is best-effort — never surface a failure to the user.
    }
  }
}
