import 'package:meta/meta.dart';

@immutable
class SearchResponseModel {
  const SearchResponseModel({
    required this.results,
    required this.total,
    required this.searchType,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    return SearchResponseModel(
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      searchType: json['search_type'] as String? ?? 'text',
    );
  }

  final List<SearchResult> results;
  final int total;
  final String searchType;
}

@immutable
class SearchResult {
  const SearchResult({
    required this.audioId,
    required this.owner,
    required this.title,
    required this.durationSec,
    required this.snippet,
    required this.matchScore,
    required this.tags,
    required this.createdAt,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      audioId: json['audio_id'] as String,
      owner: SearchOwner.fromJson(json['owner'] as Map<String, dynamic>),
      title: json['title'] as String? ?? '',
      durationSec: json['duration_sec'] as int? ?? 0,
      snippet: json['snippet'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String audioId;
  final SearchOwner owner;
  final String title;
  final int durationSec;
  final String snippet;
  final double matchScore;
  final List<String> tags;
  final DateTime createdAt;
}

@immutable
class SearchOwner {
  const SearchOwner({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory SearchOwner.fromJson(Map<String, dynamic> json) {
    return SearchOwner(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
}

