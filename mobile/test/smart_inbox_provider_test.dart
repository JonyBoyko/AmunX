import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/models/episode.dart';
import 'package:moweton_flutter/data/repositories/smart_inbox_repository.dart';
import 'package:moweton_flutter/presentation/providers/smart_inbox_provider.dart';

void main() {
  Episode buildEpisode(
    String id,
    DateTime createdAt, {
    String? summary,
    List<String>? keywords,
  }) {
    return Episode(
      id: id,
      authorId: 'author-$id',
      visibility: 'public',
      status: 'public',
      mask: 'none',
      quality: 'clean',
      createdAt: createdAt,
      durationSec: 60,
      summary: summary,
      keywords: keywords,
    );
  }

  test('SmartInboxState groups entries by day and sorts newest first', () {
    final now = DateTime(2024, 1, 10, 12);
    final episodes = [
      buildEpisode(
        'today-1',
        now.subtract(const Duration(hours: 1)),
        summary: 'Latest update',
        keywords: const ['ai'],
      ),
      buildEpisode(
        'yesterday-1',
        now.subtract(const Duration(days: 1, hours: 1)),
        keywords: const ['founders'],
      ),
      buildEpisode(
        'yesterday-2',
        now.subtract(const Duration(days: 1, minutes: 30)),
        summary: 'Deep dive',
      ),
    ];

    final state = SmartInboxState.fromEpisodes(episodes);

    expect(state.digests.length, 2);
    expect(state.digests.first.entries.first.episodeId, 'today-1');
    expect(
      state.digests.first.date.isAfter(state.digests.last.date),
      isTrue,
      reason: 'Digests should be sorted descending by day',
    );
    expect(
      state.digests.last.entries.first.createdAt
          .isAfter(state.digests.last.entries.last.createdAt),
      isTrue,
      reason: 'Entries within a digest should be newest-first',
    );
    expect(state.digests.first.summary.isNotEmpty, isTrue);
  });

  test('Highlights include most frequent keywords', () {
    final now = DateTime(2024, 2, 2, 9);
    final episodes = [
      buildEpisode(
        'a',
        now,
        keywords: const ['ai', 'product'],
      ),
      buildEpisode(
        'b',
        now.subtract(const Duration(hours: 2)),
        keywords: const ['ai', 'growth'],
      ),
      buildEpisode(
        'c',
        now.subtract(const Duration(days: 1)),
        keywords: const ['growth'],
      ),
    ];

    final state = SmartInboxState.fromEpisodes(episodes);

    expect(state.highlights, isNotEmpty);
    expect(state.highlights.contains('ai'), isTrue);
    expect(
      state.highlights.take(2).contains('growth'),
      isTrue,
      reason: 'Repeated keywords should bubble to the top',
    );
  });

  group('loadSmartInbox', () {
    SmartInboxState buildState(String highlight) {
      return SmartInboxState(
        digests: [
          SmartInboxDigest(
            date: DateTime(2024, 3, 1),
            entries: const <SmartInboxEntry>[],
            tags: const <String>[],
            summary: 'TL;DR goes here',
          ),
        ],
        highlights: [highlight],
        generatedAt: DateTime(2024, 3, 1),
      );
    }

    test('returns API data when fetch succeeds', () async {
      final repo = _FakeSmartInboxRepository(
        fetchImpl: ({token}) async => buildState('api'),
      );

      final result = await loadSmartInbox(
        repository: repo,
        token: 'token',
        enableFallback: false,
      );

      expect(result.highlights, ['api']);
      expect(repo.fetchCalls, 1);
      expect(repo.fallbackCalls, 0);
    });

    test('falls back to local digest when enabled', () async {
      final repo = _FakeSmartInboxRepository(
        fetchImpl: ({token}) => Future.error(Exception('boom')),
        fallbackImpl: ({token}) async => buildState('fallback'),
      );

      final result = await loadSmartInbox(
        repository: repo,
        token: 'token',
        enableFallback: true,
      );

      expect(result.highlights, ['fallback']);
      expect(repo.fetchCalls, 1);
      expect(repo.fallbackCalls, 1);
    });

    test('propagates error when fallback disabled', () async {
      final repo = _FakeSmartInboxRepository(
        fetchImpl: ({token}) => Future.error(Exception('boom')),
      );

      expect(
        () => loadSmartInbox(
          repository: repo,
          token: 'token',
          enableFallback: false,
        ),
        throwsException,
      );
      expect(repo.fetchCalls, 1);
      expect(repo.fallbackCalls, 0);
    });
  });
}

class _FakeSmartInboxRepository implements SmartInboxDataSource {
  _FakeSmartInboxRepository({
    this.fetchImpl,
    this.fallbackImpl,
  });

  final Future<SmartInboxState> Function({String? token})? fetchImpl;
  final Future<SmartInboxState> Function({String? token})? fallbackImpl;
  int fetchCalls = 0;
  int fallbackCalls = 0;

  @override
  Future<SmartInboxState> fetchSmartInbox({String? token}) {
    fetchCalls++;
    if (fetchImpl != null) {
      return fetchImpl!(token: token);
    }
    throw UnimplementedError('fetchImpl not provided');
  }

  @override
  Future<SmartInboxState> fallbackFromEpisodes({String? token}) {
    fallbackCalls++;
    if (fallbackImpl != null) {
      return fallbackImpl!(token: token);
    }
    throw UnimplementedError('fallbackImpl not provided');
  }
}
