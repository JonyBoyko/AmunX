import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
class Episode with _$Episode {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Episode({
    required String id,
    required String authorId,
    String? topicId,
    String? title,
    required String visibility,
    required String status,
    int? durationSec,
    String? audioUrl,
    required String mask,
    required String quality,
    @Default(false) bool isLive,
    DateTime? publishedAt,
    required DateTime createdAt,
    String? summary,
    List<String>? keywords,
    Map<String, dynamic>? mood,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
}

@freezed
class FeedResponse with _$FeedResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory FeedResponse({
    required List<Episode> items,
  }) = _FeedResponse;

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);
}

