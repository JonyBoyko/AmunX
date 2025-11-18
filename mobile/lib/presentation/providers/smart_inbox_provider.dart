import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/feed_repository.dart';
import 'session_provider.dart';

final smartInboxProvider =
    FutureProvider<SmartInboxState>((ref) async {
  final feedRepository = ref.watch(feedRepositoryProvider);
  final session = ref.watch(sessionProvider);
  try {
    final episodes = await feedRepository.getEpisodes(
      token: session.token,
      queryParameters: {'limit': 60},
    );
    return SmartInboxState.fromEpisodes(episodes);
  } catch (error, stack) {
    AppLogger.error(
      'Smart inbox fetch failed',
      tag: 'SmartInbox',
      error: error,
      stackTrace: stack,
    );
    rethrow;
  }
});

class SmartInboxState {
  SmartInboxState({
    required this.digests,
    required this.highlights,
    required this.generatedAt,
  });

  final List<SmartInboxDigest> digests;
  final List<String> highlights;
  final DateTime generatedAt;

  factory SmartInboxState.fromEpisodes(List<Episode> episodes) {
    final grouped = <DateTime, List<Episode>>{};
    final keywordTally = <String, int>{};
    final now = DateTime.now();

    for (final episode in episodes) {
      final created = episode.createdAt;
      final key = DateTime(created.year, created.month, created.day);
      grouped.putIfAbsent(key, () => []).add(episode);
      for (final keyword in episode.keywords ?? const <String>[]) {
        final normalized = keyword.toLowerCase();
        if (normalized.isEmpty) continue;
        keywordTally.update(normalized, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    final digests = grouped.entries.map((entry) {
      final entries = entry.value
          .map(
            (episode) => SmartInboxEntry(
              episode: episode,
              snippet: _buildSnippet(episode),
              tags: _topKeywords(episode.keywords ?? const [], 3),
              isNew: now.difference(episode.createdAt).inHours < 24,
            ),
          )
          .toList()
        ..sort(
          (a, b) =>
              b.episode.createdAt.compareTo(a.episode.createdAt),
        );
      final dayTags = _aggregateKeywords(entry.value, 4);
      return SmartInboxDigest(
        date: entry.key,
        entries: entries,
        tags: dayTags,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final highlights = (keywordTally.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((entry) => entry.key)
        .toList();

    return SmartInboxState(
      digests: digests,
      highlights: highlights,
      generatedAt: now,
    );
  }
}

class SmartInboxDigest {
  const SmartInboxDigest({
    required this.date,
    required this.entries,
    required this.tags,
  });

  final DateTime date;
  final List<SmartInboxEntry> entries;
  final List<String> tags;

  String get dayLabel => DateFormat.MMMMd().format(date);
}

class SmartInboxEntry {
  const SmartInboxEntry({
    required this.episode,
    required this.snippet,
    required this.tags,
    required this.isNew,
  });

  final Episode episode;
  final String snippet;
  final List<String> tags;
  final bool isNew;
}

String _buildSnippet(Episode episode) {
  final summary = episode.summary?.trim();
  if (summary != null && summary.isNotEmpty) {
    return summary;
  }
  final title = episode.title?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }
  final keywords = episode.keywords ?? const [];
  if (keywords.isNotEmpty) {
    return 'Highlights: ${keywords.take(3).join(', ')}';
  }
  return 'Новий апдейт від автора.';
}

List<String> _aggregateKeywords(List<Episode> episodes, int take) {
  final tally = <String, int>{};
  for (final episode in episodes) {
    for (final keyword in episode.keywords ?? const <String>[]) {
      final normalized = keyword.toLowerCase();
      if (normalized.isEmpty) continue;
      tally.update(normalized, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final sorted = tally.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(take).map((entry) => entry.key).toList();
}

List<String> _topKeywords(List<String> keywords, int take) {
  final normalized = keywords
      .where((keyword) => keyword.trim().isNotEmpty)
      .map((keyword) => keyword.toLowerCase())
      .take(take)
      .toList();
  return normalized;
}





