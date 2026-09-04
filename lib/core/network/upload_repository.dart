import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Uploads a local image/video file and returns the URL to store on
/// whatever record it belongs to (a listing's image_urls, a reel's
/// video_url, etc.) — the one door every image_picker flow in the app
/// goes through before it can save anything server-side.
class UploadRepository {
  final ApiClient _client;
  const UploadRepository(this._client);

  Future<String> upload(String localFilePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localFilePath),
      });
      final response = await _client.dio.post('/upload', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Uploads several files in order, preserving that order in the result.
  Future<List<String>> uploadAll(List<String> localFilePaths) async {
    final urls = <String>[];
    for (final path in localFilePaths) {
      urls.add(await upload(path));
    }
    return urls;
  }
}
