import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/search.dart';

class SearchRepository {
  SearchRepository({
    Duration cacheTtl = const Duration(minutes: 3),
  }) : _cacheTtl = cacheTtl;

  final Duration _cacheTtl;
  final Map<String, _SearchCacheEntry> _cache = {};
  static const _maxCacheEntries = 12;

  Future<SearchResponseModel> searchAudio({
    required String query,
    String? token,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final normalized = _normalizeQuery(query);
    final cacheKey = _cacheKey(normalized, limit, offset);

    if (!forceRefresh && offset == 0) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        AppLogger.debug(
          'Serving search cache for "$normalized"',
          tag: 'SearchRepository',
        );
        return cached;
      }
    }

    AppLogger.debug(
      'Searching audio (query="$normalized" limit=$limit offset=$offset)',
      tag: 'SearchRepository',
    );
    final apiClient = createApiClient(token: token);
    final response = await apiClient.searchAudio(
      query: normalized,
      limit: limit,
      offset: offset,
    );
    if (offset == 0) {
      _putInCache(cacheKey, response);
    }
    AppLogger.debug(
      'Search returned ${response.results.length} results / total ${response.total}',
      tag: 'SearchRepository',
    );
    return response;
  }

  SearchResponseModel? peekCached({
    required String query,
    int limit = 20,
  }) {
    final normalized = _normalizeQuery(query);
    final cacheKey = _cacheKey(normalized, limit, 0);
    return _getFromCache(cacheKey);
  }

  SearchResponseModel? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.storedAt) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.response;
  }

  void _putInCache(String key, SearchResponseModel response) {
    _cache[key] = _SearchCacheEntry(
      response: response,
      storedAt: DateTime.now(),
    );
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

  String _cacheKey(String query, int limit, int offset) {
    return '$query|$limit|$offset';
  }

  String _normalizeQuery(String input) => input.trim();
}

class _SearchCacheEntry {
  const _SearchCacheEntry({
    required this.response,
    required this.storedAt,
  });

  final SearchResponseModel response;
  final DateTime storedAt;
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});
