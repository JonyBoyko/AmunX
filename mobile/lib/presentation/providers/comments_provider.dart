import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/comment_repository.dart';
import 'session_provider.dart';

final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<Comment>>, String>((ref, episodeId) {
  final repository = ref.watch(commentRepositoryProvider);
  return CommentsNotifier(ref, repository, episodeId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  CommentsNotifier(this._ref, this._repository, this._episodeId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  final CommentRepository _repository;
  final String _episodeId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(sessionProvider).token;
      final comments = await _repository.fetchComments(
        _episodeId,
        token: token,
      );
      state = AsyncValue.data(comments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() => _load();

  Future<void> submit(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final token = _ref.read(sessionProvider).token;
    if (token == null) {
      throw StateError('auth_required');
    }
    try {
      final newComment = await _repository.createComment(
        episodeId: _episodeId,
        text: clean,
        token: token,
      );
      final current = state.value ?? const <Comment>[];
      state = AsyncValue.data(
        [newComment, ...current],
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'submit comment failed',
        tag: 'CommentsNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
