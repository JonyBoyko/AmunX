import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/feed_repository.dart';
import '../providers/session_provider.dart';

final feedProvider = FutureProvider<List<Episode>>((ref) async {
  final feedRepository = ref.watch(feedRepositoryProvider);
  final sessionState = ref.watch(sessionProvider);
  AppLogger.info(
    'Fetching episodes (token present: ${sessionState.token != null})',
    tag: 'FeedProvider',
  );

  try {
    final episodes = await feedRepository.getEpisodes(token: sessionState.token);
    AppLogger.info('Fetched ${episodes.length} episodes', tag: 'FeedProvider');
    return episodes;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to fetch episodes',
      tag: 'FeedProvider',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

final episodeDetailProvider = FutureProvider.family<Episode, String>((ref, episodeId) async {
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

