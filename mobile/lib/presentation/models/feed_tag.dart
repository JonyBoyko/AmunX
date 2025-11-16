import 'package:flutter/foundation.dart';

@immutable
class FeedTag {
  final String label;
  final String emoji;
  final int trendingScore;
  final bool isFollowed;

  const FeedTag({
    required this.label,
    required this.emoji,
    required this.trendingScore,
    this.isFollowed = false,
  });

  FeedTag copyWith({
    bool? isFollowed,
  }) {
    return FeedTag(
      label: label,
      emoji: emoji,
      trendingScore: trendingScore,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}

const defaultFeedTags = [
  FeedTag(label: '#AI', emoji: '🤖', trendingScore: 97),
  FeedTag(label: '#WalkCast', emoji: '🚶', trendingScore: 88),
  FeedTag(label: '#Productivity', emoji: '⚡', trendingScore: 84),
  FeedTag(label: '#Mindful', emoji: '🧘', trendingScore: 81),
  FeedTag(label: '#Kyiv', emoji: '🏙️', trendingScore: 79),
  FeedTag(label: '#Startup', emoji: '🚀', trendingScore: 77),
  FeedTag(label: '#Music', emoji: '🎧', trendingScore: 74),
  FeedTag(label: '#Wellness', emoji: '💚', trendingScore: 71),
];
