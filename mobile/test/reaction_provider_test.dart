import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/api/api_client.dart';
import 'package:moweton_flutter/data/models/episode.dart';
import 'package:moweton_flutter/data/repositories/reaction_repository.dart';
import 'package:moweton_flutter/data/repositories/auth_repository.dart';
import 'package:moweton_flutter/presentation/providers/reaction_provider.dart';
import 'package:moweton_flutter/presentation/providers/session_provider.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('syncFromEpisodes seeds snapshot state', () {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          (ref) => _FakeSessionNotifier(token: 'token'),
        ),
        reactionRepositoryProvider.overrideWithValue(
          const ReactionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final episode = Episode(
      id: 'ep-sync',
      authorId: 'author',
      visibility: 'public',
      status: 'public',
      mask: 'none',
      quality: 'clean',
      isLive: false,
      createdAt: DateTime(2024),
      reactions: const [
        ReactionStat(type: 'like', count: 4),
      ],
      selfReactions: const ['like'],
    );

    container.read(reactionProvider.notifier).syncFromEpisodes([episode]);
    final snapshot = container.read(reactionSnapshotProvider('ep-sync'));

    expect(snapshot.countFor('like'), 4);
    expect(snapshot.isActive('like'), isTrue);
  });

  test('toggleReaction updates snapshot from repository result', () async {
    final repo = _FakeReactionRepository(
      ReactionToggleResult(
        totals: const [
          ReactionStat(type: 'like', count: 2),
          ReactionStat(type: 'fire', count: 1),
        ],
        self: {'like'},
        badge: const ReactionBadge(
          type: 'like',
          label: 'Фан-фаворит',
          emoji: '👍',
          level: 2,
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          (ref) => _FakeSessionNotifier(token: 't'),
        ),
        reactionRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(reactionProvider.notifier).toggleReaction(
          'ep-toggle',
          'like',
        );

    final snapshot = container.read(reactionSnapshotProvider('ep-toggle'));
    expect(snapshot.countFor('like'), 2);
    expect(snapshot.countFor('fire'), 1);
    expect(snapshot.badge?.type, 'like');
  });
}

class _FakeReactionRepository extends ReactionRepository {
  _FakeReactionRepository(this.result);

  final ReactionToggleResult result;

  @override
  Future<ReactionToggleResult> toggleReaction({
    required String episodeId,
    required String type,
    required bool remove,
    required String token,
  }) async {
    return result;
  }
}

class _FakeSessionNotifier extends SessionNotifier {
  _FakeSessionNotifier({required String token})
      : _token = token,
        super(AuthRepository(createApiClient()));

  final String _token;

  @override
  Future<void> hydrate() async {
    state = SessionState(
      isLoading: false,
      isAuthenticated: true,
      token: _token,
    );
  }

  @override
  Future<void> setToken(String token) async {
    state = SessionState(
      isLoading: false,
      isAuthenticated: true,
      token: token,
    );
  }
}
