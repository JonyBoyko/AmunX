import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/models/comment.dart';
import 'package:moweton_flutter/data/api/api_client.dart';
import 'package:moweton_flutter/data/repositories/auth_repository.dart';
import 'package:moweton_flutter/data/repositories/comment_repository.dart';
import 'package:moweton_flutter/presentation/providers/comments_provider.dart';
import 'package:moweton_flutter/presentation/providers/session_provider.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('load comments populates state', () async {
    final repository = _FakeCommentRepository(comments: [
      Comment(
        id: '1',
        episodeId: 'ep',
        authorId: 'author',
        authorName: 'Tester',
        authorHandle: '@tester',
        text: 'Hello',
        createdAt: DateTime.utc(2024),
      ),
    ],);

    final container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith((ref) => _FakeSessionNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(commentsProvider('ep').notifier);
    await notifier.refresh();

    final state = container.read(commentsProvider('ep'));
    expect(state.hasValue, isTrue);
    expect(state.value?.length, 1);
  });

  test('submit comment appends to state', () async {
    final repository = _FakeCommentRepository(comments: []);
    final container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith((ref) => _FakeSessionNotifier(token: 't')),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(commentsProvider('ep').notifier);
    await notifier.refresh();
    await notifier.submit('New comment');

    final state = container.read(commentsProvider('ep'));
    expect(state.value?.length, 1);
    expect(state.value?.first.text, 'New comment');
  });
}

class _FakeCommentRepository extends CommentRepository {
  _FakeCommentRepository({required this.comments});

  final List<Comment> comments;

  @override
  Future<List<Comment>> fetchComments(String episodeId, {String? token}) async {
    return List<Comment>.from(comments);
  }

  @override
  Future<Comment> createComment({
    required String episodeId,
    required String text,
    required String token,
  }) async {
    final comment = Comment(
      id: 'new',
      episodeId: episodeId,
      authorId: 'user',
      authorName: 'User',
      authorHandle: '@user',
      text: text,
      createdAt: DateTime.now(),
    );
    comments.insert(0, comment);
    return comment;
  }
}

class _FakeSessionNotifier extends SessionNotifier {
  _FakeSessionNotifier({String token = 'token'})
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
