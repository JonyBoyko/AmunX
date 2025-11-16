import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/reaction_repository.dart';
import '../models/reaction_state.dart';
import 'session_provider.dart';

final reactionProvider =
    StateNotifierProvider<ReactionNotifier, Map<String, ReactionSnapshot>>(
        (ref) {
  final repository = ref.watch(reactionRepositoryProvider);
  return ReactionNotifier(ref, repository);
});

final reactionSnapshotProvider =
    Provider.family<ReactionSnapshot, String>((ref, episodeId) {
  final state = ref.watch(reactionProvider);
  return state[episodeId] ?? ReactionSnapshot.initial();
});

class ReactionNotifier extends StateNotifier<Map<String, ReactionSnapshot>> {
  ReactionNotifier(this._ref, this._repository) : super(const {});

  final Ref _ref;
  final ReactionRepository _repository;

  void syncFromEpisodes(List<Episode> episodes) {
    if (episodes.isEmpty) return;
    final next = Map<String, ReactionSnapshot>.from(state);
    var mutated = false;

    for (final episode in episodes) {
      final snapshot = ReactionSnapshot.fromEpisode(episode);
      final previous = next[episode.id];
      if (previous == null || !_snapshotEquals(previous, snapshot)) {
        next[episode.id] = snapshot;
        mutated = true;
      }
    }

    if (mutated) {
      state = next;
    }
  }

  Future<void> toggleReaction(String episodeId, String type) async {
    final token = _ref.read(sessionProvider).token;
    if (token == null) {
      throw StateError('auth_required');
    }

    final current = state[episodeId] ?? ReactionSnapshot.initial();
    final isActive = current.isActive(type);
    final totals = Map<String, int>.from(current.totals);
    final active = Set<String>.from(current.activeTypes);
    totals[type] = (totals[type] ?? 0) + (isActive ? -1 : 1);
    if (totals[type]! < 0) {
      totals[type] = 0;
    }
    if (isActive) {
      active.remove(type);
    } else {
      active.add(type);
    }
    final optimistic =
        current.copyWith(totals: totals, activeTypes: active, isUpdating: true);
    state = {
      ...state,
      episodeId: optimistic,
    };

    try {
      final response = await _repository.toggleReaction(
        episodeId: episodeId,
        type: type,
        remove: isActive,
        token: token,
      );
      final nextSnapshot = ReactionSnapshot.fromStats(
        stats: response.totals,
        activeTypes: response.self,
        badge: response.badge,
      );
      state = {
        ...state,
        episodeId: nextSnapshot,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'toggleReaction failed',
        tag: 'ReactionProvider',
        error: e,
        stackTrace: stackTrace,
      );
      state = {
        ...state,
        episodeId: current,
      };
      rethrow;
    }
  }
}

bool _snapshotEquals(ReactionSnapshot a, ReactionSnapshot b) {
  if (a.isUpdating != b.isUpdating) return false;
  if (!mapEquals(a.totals, b.totals)) return false;
  if (!setEquals(a.activeTypes, b.activeTypes)) return false;
  return a.badge == b.badge;
}
