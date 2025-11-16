import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/episode.dart';

class FeedRepository {
  FeedRepository();

  Future<List<Episode>> getEpisodes({String? token}) async {
    AppLogger.debug('Creating API client for episodes (hasToken=${token != null})', tag: 'FeedRepository');
    final apiClient = createApiClient(token: token);
    final response = await apiClient.getEpisodes();
    AppLogger.debug('API returned ${response.items.length} episodes', tag: 'FeedRepository');
    return response.items;
  }

  Future<Episode> getEpisodeById(String id, {String? token}) async {
    AppLogger.debug('Fetching episode $id (hasToken=${token != null})', tag: 'FeedRepository');
    final apiClient = createApiClient(token: token);
    return apiClient.getEpisodeById(id);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

