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
      // A photo clears the client's normal 15s timeout easily, but a video
      // (even compressed) can take a lot longer to actually send over a
      // typical connection — this only loosens the timeout for this one
      // request, not every other call the app makes.
      final response = await _client.dio.post(
        '/upload',
        data: formData,
        options: Options(sendTimeout: const Duration(minutes: 3), receiveTimeout: const Duration(seconds: 30)),
      );
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
