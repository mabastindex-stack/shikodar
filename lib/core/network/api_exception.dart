import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// Thrown for any failed API call, carrying a message ready to show
/// directly in a SnackBar — the backend's own message when present,
/// otherwise a generic localized fallback.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String);
    }
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final firstList = errors.values.first;
      if (firstList is List && firstList.isNotEmpty) {
        return ApiException(firstList.first.toString());
      }
    }
    return ApiException('auth.network_error'.tr());
  }

  @override
  String toString() => message;
}
