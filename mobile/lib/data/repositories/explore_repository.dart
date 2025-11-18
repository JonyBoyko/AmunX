import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/explore.dart';

class ExploreRepository {
  ExploreRepository({
    Duration cacheTtl = const Duration(minutes: 3),
  }) : _cacheTtl = cacheTtl;

  final Duration _cacheTtl;
  final Map<String, _CachedExplorePage> _cache = {};
  static const _maxCacheEntries = 8;

  Future<ExploreFeedPage> fetchExploreFeed({
    String? token,
    String? userId,
    int limit = 20,
    String? cursor,
    List<String>? tags,
    List<String>? topicIds,
    int? minLength,
    int? maxLength,
    bool forceRefresh = false,
  }) async {
    final normalizedTags = _normalizeList(tags);
    final normalizedTopics = _normalizeList(topicIds);
    final cacheKey = _cacheKey(
      userId: userId,
      limit: limit,
      tags: normalizedTags,
      topicIds: normalizedTopics,
      minLength: minLength,
      maxLength: maxLength,
    );

    if (!forceRefresh && cursor == null) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        AppLogger.debug(
          'Serving explore feed from cache (key=$cacheKey)',
          tag: 'ExploreRepository',
        );
        return cached;
      }
    }

    AppLogger.debug(
      'Fetching explore feed (limit=$limit cursor=$cursor tags=${normalizedTags.join(',')})',
      tag: 'ExploreRepository',
    );
    final apiClient = createApiClient(token: token);
    final page = await apiClient.getExploreFeed(
      limit: limit,
      cursor: cursor,
      tags: normalizedTags.isEmpty ? null : normalizedTags,
      topicIds: normalizedTopics.isEmpty ? null : normalizedTopics,
      minLength: minLength,
      maxLength: maxLength,
    );
    if (cursor == null) {
      _putInCache(cacheKey, page);
    }
    AppLogger.debug(
      'Explore feed returned ${page.cards.length} cards (next=${page.nextCursor})',
      tag: 'ExploreRepository',
    );
    return page;
  }

  ExploreFeedPage? peekCachedFeed({
    String? userId,
    int limit = 20,
    List<String>? tags,
    List<String>? topicIds,
    int? minLength,
    int? maxLength,
  }) {
    final cacheKey = _cacheKey(
      userId: userId,
      limit: limit,
      tags: _normalizeList(tags),
      topicIds: _normalizeList(topicIds),
      minLength: minLength,
      maxLength: maxLength,
    );
    return _getFromCache(cacheKey);
  }

  ExploreFeedPage? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.storedAt) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.page;
  }

  void _putInCache(String key, ExploreFeedPage page) {
    _cache[key] = _CachedExplorePage(page: page, storedAt: DateTime.now());
    if (_cache.length > _maxCacheEntries) {
      String? oldestKey;
      DateTime? oldestTime;
      _cache.forEach((candidateKey, entry) {
        if (oldestTime == null || entry.storedAt.isBefore(oldestTime!)) {
          oldestKey = candidateKey;
          oldestTime = entry.storedAt;
        }
      });
      if (oldestKey != null) {
        _cache.remove(oldestKey);
      }
    }
  }

  String _cacheKey({
    required String? userId,
    required int limit,
    required List<String> tags,
    required List<String> topicIds,
    required int? minLength,
    required int? maxLength,
  }) {
    final buffer = StringBuffer()
      ..write('user=${userId ?? 'anon'}|')
      ..write('limit=$limit|')
      ..write('tags=${tags.join(',')}|')
      ..write('topics=${topicIds.join(',')}|')
      ..write('min=${minLength ?? -1}|')
      ..write('max=${maxLength ?? -1}');
    return buffer.toString();
  }

  List<String> _normalizeList(List<String>? values) {
    if (values == null || values.isEmpty) {
      return const [];
    }
    final set = <String>{};
    for (final value in values) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isNotEmpty) {
        set.add(normalized);
      }
    }
    final list = set.toList()..sort();
    return list;
  }
}

class _CachedExplorePage {
  const _CachedExplorePage({
    required this.page,
    required this.storedAt,
  });

  final ExploreFeedPage page;
  final DateTime storedAt;
}

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepository();
});
