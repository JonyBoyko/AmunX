import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/explore.dart';

class ExploreRepository {
  ExploreRepository();

  Future<ExploreFeedPage> fetchExploreFeed({
    String? token,
    int limit = 20,
    String? cursor,
    List<String>? tags,
    List<String>? topicIds,
    int? minLength,
    int? maxLength,
  }) async {
    AppLogger.debug(
      'Fetching explore feed (limit=$limit cursor=$cursor tags=${tags?.join(',')})',
      tag: 'ExploreRepository',
    );
    final apiClient = createApiClient(token: token);
    final page = await apiClient.getExploreFeed(
      limit: limit,
      cursor: cursor,
      tags: tags,
      topicIds: topicIds,
      minLength: minLength,
      maxLength: maxLength,
    );
    AppLogger.debug(
      'Explore feed returned ${page.cards.length} cards (next=${page.nextCursor})',
      tag: 'ExploreRepository',
    );
    return page;
  }
}

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepository();
});

