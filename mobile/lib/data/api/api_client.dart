import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../models/episode.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Auth
  Future<void> requestMagicLink(Map<String, dynamic> body) async {
    await _dio.post('/v1/auth/magiclink', data: body);
  }

  Future<Map<String, dynamic>> verifyMagicLink(Map<String, dynamic> body) async {
    final response = await _dio.post('/v1/auth/magiclink/verify', data: body);
    return response.data as Map<String, dynamic>;
  }

  // Episodes
  Future<FeedResponse> getEpisodes() async {
    final response = await _dio.get('/v1/episodes');
    return FeedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Episode> getEpisodeById(String id) async {
    final response = await _dio.get('/v1/episodes/$id');
    return Episode.fromJson(response.data as Map<String, dynamic>);
  }

  // Comments
  Future<List<dynamic>> getComments(String episodeId) async {
    final response = await _dio.get('/v1/episodes/$episodeId/comments');
    return response.data as List<dynamic>;
  }

  Future<dynamic> createComment(String episodeId, Map<String, dynamic> body) async {
    final response = await _dio.post('/v1/episodes/$episodeId/comments', data: body);
    return response.data;
  }

  // Topics
  Future<List<dynamic>> getTopics() async {
    final response = await _dio.get('/v1/topics');
    return response.data as List<dynamic>;
  }

  Future<dynamic> getTopicById(String topicId) async {
    final response = await _dio.get('/v1/topics/$topicId');
    return response.data;
  }
}

ApiClient createApiClient({String? token}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl.replaceAll('/v1', ''),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.debug(
          'HTTP ${options.method} ${options.uri}',
          tag: 'ApiClient',
        );
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug(
          'HTTP ${response.requestOptions.method} ${response.requestOptions.uri} '
          '→ ${response.statusCode}',
          tag: 'ApiClient',
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error(
          'HTTP ${error.requestOptions.method} ${error.requestOptions.uri} failed',
          tag: 'ApiClient',
          error: error,
          stackTrace: error.stackTrace,
        );
        return handler.next(error);
      },
    ),
  );

  return ApiClient(dio);
}

