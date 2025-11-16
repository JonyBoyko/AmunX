import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/models/episode.dart';
import 'package:moweton_flutter/presentation/filters/feed_filters.dart';
import 'package:moweton_flutter/presentation/utils/feed_classifiers.dart';

Episode _episode({
  required String id,
  int? duration,
  bool isLive = false,
  List<String>? keywords,
}) {
  return Episode(
    id: id,
    authorId: 'author_$id',
    visibility: 'public',
    status: 'public',
    mask: 'none',
    quality: 'clean',
    isLive: isLive,
    createdAt: DateTime.utc(2024, 1, 1),
    durationSec: duration,
    keywords: keywords,
  );
}

void main() {
  group('classifyFormat', () {
    test('returns shorts for sub-2-minute clips', () {
      final episode = _episode(id: 'short', duration: 90);
      expect(classifyFormat(episode), equals(ContentFormat.shorts));
    });

    test('returns podcasts for longer content', () {
      final episode = _episode(id: 'long', duration: 360);
      expect(classifyFormat(episode), equals(ContentFormat.podcasts));
    });

    test('returns live when episode is live', () {
      final episode = _episode(id: 'live', duration: 10, isLive: true);
      expect(classifyFormat(episode), equals(ContentFormat.live));
    });
  });

  test('deriveRegion is deterministic per episode id', () {
    final episode = _episode(id: 'region-check');
    final first = deriveRegion(episode);
    final second = deriveRegion(episode);
    expect(first, equals(second));
  });

  test('matchesRegion always true for global filter', () {
    final episode = _episode(id: 'any');
    expect(matchesRegion(episode, RegionFilter.global), isTrue);
  });

  test('matchesTags respects normalized tag set', () {
    final selected = {'#ai', '#wellness'};
    final episode = _episode(id: 'ai', keywords: ['AI', '#focus']);
    expect(matchesTags(episode, selected), isTrue);

    final other = _episode(id: 'travel', keywords: ['travel']);
    expect(matchesTags(other, selected), isFalse);
  });

  test('recommendationScore prioritizes lives and longer episodes', () {
    final short = _episode(id: 'short', duration: 60, keywords: ['note']);
    final live =
        _episode(id: 'live', duration: 60, isLive: true, keywords: ['note']);

    expect(recommendationScore(live), greaterThan(recommendationScore(short)));
  });

  test('liveAudienceEstimate stable per episode', () {
    final liveEpisode = _episode(id: 'live-user', duration: 80, isLive: true);
    final first = liveAudienceEstimate(liveEpisode);
    final second = liveAudienceEstimate(liveEpisode);
    expect(first, equals(second));
    expect(first, greaterThan(0));
  });
}
