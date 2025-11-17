import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/search.dart';

class SearchRepository {
  SearchRepository();

  Future<SearchResponseModel> searchAudio({
    required String query,
    String? token,
    int limit = 20,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Searching audio (query="$query" limit=$limit offset=$offset)',
      tag: 'SearchRepository',
    );
    final apiClient = createApiClient(token: token);
    final response = await apiClient.searchAudio(
      query: query,
      limit: limit,
      offset: offset,
    );
    AppLogger.debug(
      'Search returned ${response.results.length} results / total ${response.total}',
      tag: 'SearchRepository',
    );
    return response;
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});

