import 'package:meta/meta.dart';

@immutable
class ExploreFeedPage {
  const ExploreFeedPage({
    required this.cards,
    required this.nextCursor,
    required this.hasMore,
  });

  factory ExploreFeedPage.fromJson(Map<String, dynamic> json) {
    final cards = (json['cards'] as List<dynamic>? ?? [])
        .map((item) => ExploreCard.fromJson(item as Map<String, dynamic>))
        .toList();
    return ExploreFeedPage(
      cards: cards,
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? (json['next_cursor'] != null),
    );
  }

  final List<ExploreCard> cards;
  final String? nextCursor;
  final bool hasMore;
}

@immutable
class ExploreCard {
  const ExploreCard({
    required this.id,
    required this.kind,
    this.parentAudioId,
    required this.owner,
    required this.durationSec,
    required this.previewSentence,
    this.title,
    this.quote,
    required this.tags,
    required this.waveformPeaks,
    required this.audioUrl,
    required this.createdAt,
    this.stats,
    this.rankScore,
  });

  factory ExploreCard.fromJson(Map<String, dynamic> json) {
    return ExploreCard(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'audio_item',
      parentAudioId: json['parent_audio_id'] as String?,
      owner: ExploreOwner.fromJson(json['owner'] as Map<String, dynamic>),
      durationSec: json['duration_sec'] as int? ?? 0,
      previewSentence: json['preview_sentence'] as String? ?? '',
      title: json['title'] as String?,
      quote: json['quote'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      waveformPeaks: (json['waveform_peaks'] as List<dynamic>? ?? const [])
          .map(
            (value) =>
                value is num ? value.toDouble() : double.tryParse('$value') ?? 0,
          )
          .toList(),
      audioUrl: json['audio_url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      stats: json['stats'] == null
          ? null
          : ExploreStats.fromJson(json['stats'] as Map<String, dynamic>),
      rankScore: (json['rank_score'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String kind;
  final String? parentAudioId;
  final ExploreOwner owner;
  final int durationSec;
  final String previewSentence;
  final String? title;
  final String? quote;
  final List<String> tags;
  final List<double> waveformPeaks;
  final String audioUrl;
  final DateTime createdAt;
  final ExploreStats? stats;
  final double? rankScore;
}

@immutable
class ExploreOwner {
  const ExploreOwner({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory ExploreOwner.fromJson(Map<String, dynamic> json) {
    return ExploreOwner(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
}

@immutable
class ExploreStats {
  const ExploreStats({
    required this.likes,
    required this.saves,
    required this.plays,
  });

  factory ExploreStats.fromJson(Map<String, dynamic> json) {
    return ExploreStats(
      likes: json['likes'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      plays: json['plays'] as int? ?? 0,
    );
  }

  final int likes;
  final int saves;
  final int plays;
}

