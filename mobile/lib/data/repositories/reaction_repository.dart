import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../api/api_client.dart';
import '../models/episode.dart';

class ReactionToggleResult {
  final List<ReactionStat> totals;
  final Set<String> self;
  final ReactionBadge? badge;

  ReactionToggleResult({
    required this.totals,
    required this.self,
    required this.badge,
  });
}

class ReactionRepository {
  const ReactionRepository();

  Future<ReactionToggleResult> toggleReaction({
    required String episodeId,
    required String type,
    required bool remove,
    required String token,
  }) async {
    final client = createApiClient(token: token);
    final payload = await client.reactToEpisode(
      episodeId: episodeId,
      type: type,
      remove: remove,
    );
    final totals = (payload['totals'] as List<dynamic>? ?? const [])
        .map((entry) => ReactionStat.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ))
        .toList();
    final self =
        Set<String>.from(payload['self'] as List<dynamic>? ?? const []);
    final badgeJson = payload['badge'];
    final badge = badgeJson is Map<String, dynamic>
        ? ReactionBadge.fromJson(Map<String, dynamic>.from(badgeJson))
        : null;
    return ReactionToggleResult(totals: totals, self: self, badge: badge);
  }

  Future<Set<String>> fetchSelf({
    required String episodeId,
    required String token,
  }) async {
    final client = createApiClient(token: token);
    try {
      final response = await client.getSelfReactions(episodeId);
      return Set<String>.from(response);
    } catch (e, stackTrace) {
      AppLogger.error(
        'fetchSelf reactions failed for $episodeId',
        tag: 'ReactionRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

final reactionRepositoryProvider = Provider<ReactionRepository>(
  (ref) => const ReactionRepository(),
);
