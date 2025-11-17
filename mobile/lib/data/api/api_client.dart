import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../models/episode.dart';
import '../models/explore.dart';
import '../models/search.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Auth
  Future<Map<String, dynamic>> requestMagicLink(
      Map<String, dynamic> body) async {
    final response = await _dio.post('/v1/auth/magiclink', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyMagicLink(
      Map<String, dynamic> body) async {
    final response = await _dio.post('/v1/auth/magiclink/verify', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> devLogin(String email) async {
    final response = await _dio.post(
      '/v1/auth/dev-login',
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final response = await _dio.get('/v1/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createEpisode(Map<String, dynamic> body) async {
    final response = await _dio.post('/v1/episodes', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> finalizeEpisode(String episodeId) async {
    await _dio.post('/v1/episodes/$episodeId/finalize');
  }

  // Episodes
  Future<FeedResponse> getEpisodes({
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(
      '/v1/episodes',
      queryParameters: queryParameters,
    );
    return FeedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Episode> getEpisodeById(String id) async {
    final response = await _dio.get('/v1/episodes/$id');
    return Episode.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExploreFeedPage> getExploreFeed({
    int? limit,
    String? cursor,
    List<String>? tags,
    List<String>? topicIds,
    int? minLength,
    int? maxLength,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (limit != null) queryParameters['limit'] = limit;
    if (cursor != null) queryParameters['cursor'] = cursor;
    if (tags != null && tags.isNotEmpty) {
      queryParameters['tags'] = tags.join(',');
    }
    if (topicIds != null && topicIds.isNotEmpty) {
      queryParameters['topic_ids'] = topicIds.join(',');
    }
    final min = minLength ?? 0;
    final max = maxLength ?? 0;
    if (min > 0 || max > 0) {
      queryParameters['len'] = '$min..$max';
    }
    final response = await _dio.get(
      '/v1/explore',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return ExploreFeedPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SearchResponseModel> searchAudio({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/v1/search',
      queryParameters: {
        'q': query,
        'limit': limit,
        'offset': offset,
      },
    );
    return SearchResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // Comments
  Future<List<dynamic>> getComments(String episodeId) async {
    final response = await _dio.get('/v1/episodes/$episodeId/comments');
    final data = response.data as Map<String, dynamic>;
    return data['items'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createComment(
      String episodeId, Map<String, dynamic> body) async {
    final response =
        await _dio.post('/v1/episodes/$episodeId/comments', data: body);
    return response.data as Map<String, dynamic>;
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

  // Users
  Future<Map<String, dynamic>> followUser(String userId) async {
    final response = await _dio.post('/v1/users/$userId/follow');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    final response = await _dio.delete('/v1/users/$userId/follow');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAuthorProfiles(List<String> ids) async {
    final response = await _dio.get(
      '/v1/users/profiles',
      queryParameters: {
        'ids': ids.join(','),
      },
    );
    return (response.data as Map<String, dynamic>)['profiles'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getBillingProducts() async {
    final response = await _dio.get('/v1/billing/products');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBillingSubscription() async {
    final response = await _dio.get('/v1/billing/subscription');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBillingPortal() async {
    final response = await _dio.post('/v1/billing/portal');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMonoPayCheckout({
    required String productCode,
    String? successUrl,
  }) async {
    final response = await _dio.post(
      '/v1/billing/monopay/checkout',
      data: {
        'product_code': productCode,
        if (successUrl != null) 'success_url': successUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLiveSessions({int? limit}) async {
    final response = await _dio.get(
      '/v1/live/sessions',
      queryParameters: {
        if (limit != null) 'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> registerPushDevice({
    required String token,
    required String platform,
    String? deviceId,
    String? locale,
    String? appVersion,
  }) async {
    await _dio.post(
      '/v1/push/devices',
      data: {
        'token': token,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
        if (locale != null) 'locale': locale,
        if (appVersion != null) 'app_version': appVersion,
      },
    );
  }

  Future<void> unregisterPushDevice(String token) async {
    await _dio.delete('/v1/push/devices/$token');
  }

  // Live
  Future<Map<String, dynamic>> createLiveSession({
    required String title,
    String? topicId,
    String mask = 'none',
  }) async {
    final response = await _dio.post(
      '/v1/live/sessions',
      data: {
        'title': title,
        'mask': mask,
        if (topicId != null) 'topic_id': topicId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> endLiveSession(
    String sessionId, {
    int? durationSec,
    String? recordingKey,
  }) async {
    await _dio.post(
      '/v1/live/sessions/$sessionId/end',
      data: {
        if (durationSec != null) 'duration_sec': durationSec,
        if (recordingKey != null && recordingKey.isNotEmpty)
          'recording_key': recordingKey,
      },
    );
  }

  Future<Map<String, dynamic>> getLiveSession(
    String sessionId, {
    String role = 'listener',
  }) async {
    final response = await _dio.get(
      '/v1/live/sessions/$sessionId',
      queryParameters: {
        'role': role,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Reactions
  Future<Map<String, dynamic>> reactToEpisode({
    required String episodeId,
    required String type,
    required bool remove,
  }) async {
    final response = await _dio.post(
      '/v1/episodes/$episodeId/react',
      data: {
        'type': type,
        'remove': remove,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSelfReactions(String episodeId) async {
    final response = await _dio.get('/v1/episodes/$episodeId/reactions/self');
    return (response.data as Map<String, dynamic>)['self'] as List<dynamic>;
  }

  Future<void> uploadDevEpisode({
    required String filePath,
    required int durationSeconds,
    String? title,
    String? topicId,
  }) async {
    final ext = p.extension(filePath).replaceFirst('.', '');
    final mediaSubtype = ext.isEmpty ? 'm4a' : ext;

    final formData = FormData.fromMap({
      if (title != null && title.isNotEmpty) 'title': title,
      'duration': durationSeconds.toString(),
      if (topicId != null) 'topic_id': topicId,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
        contentType: MediaType('audio', mediaSubtype),
      ),
    });

    await _dio.post('/v1/episodes/dev', data: formData);
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
