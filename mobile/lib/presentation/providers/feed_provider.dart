import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/feed_repository.dart';
import '../filters/feed_filters.dart';
import '../utils/feed_classifiers.dart';
import 'feed_filter_provider.dart';
import 'session_provider.dart';
import 'reaction_provider.dart';

final feedProvider = FutureProvider<List<Episode>>((ref) async {
  final feedRepository = ref.watch(feedRepositoryProvider);
  final sessionState = ref.watch(sessionProvider);
  final filterState = ref.watch(feedFilterProvider);
  AppLogger.info(
    'Fetching episodes (token present: ${sessionState.token != null}, '
    'tab=${filterState.tab.name}, format=${filterState.format.name}, '
    'region=${filterState.region.name}, tags=${filterState.selectedTags.length})',
    tag: 'FeedProvider',
  );

  try {
    final episodes = await feedRepository.getEpisodes(
      token: sessionState.token,
      queryParameters: filterState.toQueryParameters(),
    );
    ref.read(reactionProvider.notifier).syncFromEpisodes(episodes);
    final filtered = _applyLocalFilters(episodes, filterState);
    AppLogger.info(
      'Fetched ${episodes.length} episodes → ${filtered.length} after filters',
      tag: 'FeedProvider',
    );
    return filtered;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to fetch episodes, returning empty list',
      tag: 'FeedProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Повертаємо порожній список замість помилки, щоб додаток не зависав
    AppLogger.info('FeedProvider: Returning empty list to show empty state', tag: 'FeedProvider');
    return [];
  }
});

final episodeDetailProvider =
    FutureProvider.family<Episode, String>((ref, episodeId) async {
  final feedRepository = ref.watch(feedRepositoryProvider);
  final sessionState = ref.watch(sessionProvider);
  AppLogger.debug('Fetching episode $episodeId', tag: 'EpisodeProvider');

  try {
    final episode = await feedRepository.getEpisodeById(
      episodeId,
      token: sessionState.token,
    );
    return episode;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to fetch episode $episodeId',
      tag: 'EpisodeProvider',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

List<Episode> _applyLocalFilters(
  List<Episode> episodes,
  FeedFilterState filters,
) {
  Iterable<Episode> working = episodes.where(
    (episode) => matchesRegion(
      episode,
      filters.tab == FeedTab.trendingNearby
          ? RegionFilter.nearby
          : filters.region,
    ),
  );

  if (filters.selectedTags.isNotEmpty) {
    working = working.where(
      (episode) => matchesTags(episode, filters.selectedTags.toSet()),
    );
  }

  switch (filters.tab) {
    case FeedTab.subscriptions:
      working = working.where(matchesSubscriptions);
      break;
    case FeedTab.recommended:
      final scored = working.toList()
        ..sort(
          (a, b) => recommendationScore(b).compareTo(recommendationScore(a)),
        );
      final takeCount = scored.isEmpty ? 0 : (scored.length / 2).ceil();
      working = scored.take(takeCount);
      break;
    case FeedTab.trendingNearby:
      working = working.where(
        (episode) => matchesRegion(episode, RegionFilter.nearby),
      );
      break;
    case FeedTab.all:
      break;
  }

  switch (filters.format) {
    case ContentFormat.shorts:
      working = working.where(
        (episode) => classifyFormat(episode) == ContentFormat.shorts,
      );
      break;
    case ContentFormat.podcasts:
      working = working.where(
        (episode) => classifyFormat(episode) == ContentFormat.podcasts,
      );
      break;
    case ContentFormat.live:
      working = working.where((episode) => episode.isLive);
      break;
  }

  return working.toList();
}
