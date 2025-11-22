import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/smart_inbox_repository.dart';
import 'session_provider.dart';

final smartInboxProvider = FutureProvider<SmartInboxState>((ref) async {
  final repo = ref.read(smartInboxRepositoryProvider);
  final session = ref.watch(sessionProvider);
  try {
    return await loadSmartInbox(
      repository: repo,
      token: session.token,
      enableFallback: AppConfig.smartInboxFallbackEnabled,
    );
  } catch (e, stack) {
    AppLogger.error(
      'Smart inbox failed, returning empty state',
      tag: 'SmartInbox',
      error: e,
      stackTrace: stack,
    );
    // Повертаємо порожній стан замість помилки
    return SmartInboxState(
      digests: [],
      highlights: [],
      generatedAt: DateTime.now(),
    );
  }
});

@visibleForTesting
Future<SmartInboxState> loadSmartInbox({
  required SmartInboxDataSource repository,
  required String? token,
  required bool enableFallback,
}) async {
  try {
    return await repository.fetchSmartInbox(token: token);
  } catch (error, stack) {
    AppLogger.error(
      'Smart inbox API failed, falling back to local digest',
      tag: 'SmartInbox',
      error: error,
      stackTrace: stack,
    );
    if (!enableFallback) {
      rethrow;
    }
    try {
      return await repository.fallbackFromEpisodes(token: token);
    } catch (fallbackError, fallbackStack) {
      AppLogger.error(
        'Smart inbox fallback failed',
        tag: 'SmartInbox',
        error: fallbackError,
        stackTrace: fallbackStack,
      );
      rethrow;
    }
  }
}

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
        keywordTally.update(
          normalized,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final digests = grouped.entries.map((entry) {
      final entries = entry.value
          .map(
            (episode) => SmartInboxEntry(
              episodeId: episode.id,
              title: episode.title ?? 'Без назви',
              snippet: _buildSnippet(episode),
              tags: _topKeywords(episode.keywords ?? const [], 3),
              isNew: now.difference(episode.createdAt).inHours < 24,
              createdAt: episode.createdAt,
            ),
          )
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
      final dayTags = _aggregateKeywords(entry.value, 4);
      final summary = _buildDigestSummary(entries);
      return SmartInboxDigest(
        date: entry.key,
        entries: entries,
        tags: dayTags,
        summary: summary,
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

  factory SmartInboxState.fromJson(Map<String, dynamic> json) {
    final digests = (json['digests'] as List<dynamic>? ?? const [])
        .map(
          (item) => SmartInboxDigest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final highlights = (json['highlights'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString())
        .toList();
    final generatedAt =
        DateTime.tryParse(json['generated_at'] as String? ?? '') ??
            DateTime.now();
    return SmartInboxState(
      digests: digests,
      highlights: highlights,
      generatedAt: generatedAt,
    );
  }
}

class SmartInboxDigest {
  const SmartInboxDigest({
    required this.date,
    required this.entries,
    required this.tags,
    required this.summary,
    this.taskCount = 0,
    this.aiSummary = '',
  });

  final DateTime date;
  final List<SmartInboxEntry> entries;
  final List<String> tags;
  final String summary;
  final int taskCount;
  final String aiSummary;

  String get dayLabel => DateFormat.MMMMd().format(date);
  
  int get totalTaskCount {
    if (taskCount > 0) return taskCount;
    return entries.fold(0, (sum, entry) => sum + entry.taskCount);
  }

  factory SmartInboxDigest.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? const [])
        .map(
          (item) => SmartInboxEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final tags = (json['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString())
        .toList();
    final parsedSummary = (json['summary'] as String?)?.trim() ?? '';
    final summary =
        parsedSummary.isNotEmpty ? parsedSummary : _buildDigestSummary(entries);
    return SmartInboxDigest(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      entries: entries,
      tags: tags,
      summary: summary,
      taskCount: json['task_count'] as int? ?? 0,
      aiSummary: (json['ai_summary'] as String?)?.trim() ?? '',
    );
  }
}

class SmartInboxEntry {
  const SmartInboxEntry({
    required this.episodeId,
    required this.title,
    required this.snippet,
    required this.tags,
    required this.isNew,
    required this.createdAt,
    this.tasks = const [],
    this.quotedBlocks = const [],
    this.taskCount = 0,
    this.aiGenerated = false,
  });

  final String episodeId;
  final String title;
  final String snippet;
  final List<String> tags;
  final bool isNew;
  final DateTime createdAt;
  final List<SmartInboxTask> tasks;
  final List<String> quotedBlocks;
  final int taskCount;
  final bool aiGenerated;

  factory SmartInboxEntry.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List<dynamic>? ?? const [];
    final tasks = tasksJson
        .map((t) => SmartInboxTask.fromJson(
              Map<String, dynamic>.from(t as Map),
            ))
        .toList();
    
    final quotedBlocks = (json['quoted_blocks'] as List<dynamic>? ?? const [])
        .map((q) => q.toString())
        .toList();

    return SmartInboxEntry(
      episodeId: json['episode_id'] as String,
      title: (json['title'] as String?) ?? 'Без назви',
      snippet: (json['snippet'] as String?) ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      isNew: json['is_new'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      tasks: tasks,
      quotedBlocks: quotedBlocks,
      taskCount: json['task_count'] as int? ?? tasks.length,
      aiGenerated: json['ai_generated'] as bool? ?? false,
    );
  }
}

class SmartInboxTask {
  const SmartInboxTask({
    required this.id,
    required this.text,
    this.completed = false,
  });

  final String id;
  final String text;
  final bool completed;

  factory SmartInboxTask.fromJson(Map<String, dynamic> json) {
    return SmartInboxTask(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
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
      tally.update(
        normalized,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
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

String _buildDigestSummary(List<SmartInboxEntry> entries) {
  final snippets = <String>[];
  for (final entry in entries) {
    final snippet = entry.snippet.trim();
    final fallback = entry.title.trim();
    final candidate = snippet.isNotEmpty ? snippet : fallback;
    if (candidate.isEmpty) continue;
    snippets.add(candidate);
    if (snippets.length == 3) break;
  }
  if (snippets.isEmpty) {
    return '';
  }
  final joined = snippets.join(' • ');
  return joined.length > 220 ? '${joined.substring(0, 219)}…' : joined;
}
