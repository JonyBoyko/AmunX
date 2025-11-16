import 'dart:math';

import '../../data/models/episode.dart';
import '../filters/feed_filters.dart';
import '../models/feed_tag.dart';

enum EpisodeRegion {
  kyiv,
  lviv,
  warsaw,
  berlin,
  newYork,
}

extension EpisodeRegionX on EpisodeRegion {
  String get label {
    switch (this) {
      case EpisodeRegion.kyiv:
        return 'Київ';
      case EpisodeRegion.lviv:
        return 'Львів';
      case EpisodeRegion.warsaw:
        return 'Варшава';
      case EpisodeRegion.berlin:
        return 'Берлін';
      case EpisodeRegion.newYork:
        return 'Нью-Йорк';
    }
  }

  bool get isEurope {
    switch (this) {
      case EpisodeRegion.kyiv:
      case EpisodeRegion.lviv:
      case EpisodeRegion.warsaw:
      case EpisodeRegion.berlin:
        return true;
      case EpisodeRegion.newYork:
        return false;
    }
  }
}

ContentFormat classifyFormat(Episode episode) {
  if (episode.isLive) {
    return ContentFormat.live;
  }
  final duration = episode.durationSec ?? 0;
  if (duration == 0) {
    return ContentFormat.shorts;
  }
  return duration <= 120 ? ContentFormat.shorts : ContentFormat.podcasts;
}

EpisodeRegion deriveRegion(Episode episode) {
  final bucket = episode.id.hashCode.abs() % EpisodeRegion.values.length;
  return EpisodeRegion.values[bucket];
}

bool matchesRegion(Episode episode, RegionFilter filter) {
  final region = deriveRegion(episode);
  switch (filter) {
    case RegionFilter.global:
      return true;
    case RegionFilter.nearby:
      return region == EpisodeRegion.kyiv;
    case RegionFilter.europe:
      return region.isEurope;
    case RegionFilter.northAmerica:
      return region == EpisodeRegion.newYork;
  }
}

bool matchesFormat(Episode episode, ContentFormat format) {
  return classifyFormat(episode) == format;
}

List<String> deriveTags(Episode episode) {
  final keywords = episode.keywords;
  if (keywords != null && keywords.isNotEmpty) {
    return keywords
        .map((keyword) => '#${keyword.replaceAll('#', '').toLowerCase()}')
        .toList();
  }

  final fallback =
      defaultFeedTags.map((tag) => tag.label.toLowerCase()).toList();
  final seed = episode.id.hashCode.abs();
  return [
    fallback[seed % fallback.length],
    fallback[(seed + 3) % fallback.length],
  ];
}

bool matchesTags(Episode episode, Set<String> selectedTags) {
  if (selectedTags.isEmpty) {
    return true;
  }
  final episodeTags = deriveTags(episode).toSet();
  return selectedTags.any(episodeTags.contains);
}

bool matchesSubscriptions(Episode episode) {
  return episode.authorId.hashCode.abs() % 3 == 0;
}

int recommendationScore(Episode episode) {
  final base = (episode.durationSec ?? 90);
  final liveBoost = episode.isLive ? 120 : 0;
  final tagBonus = (episode.keywords?.length ?? 1) * 20;
  final randomBoost = Random(episode.id.hashCode).nextInt(60);
  return base + liveBoost + tagBonus + randomBoost;
}

int liveAudienceEstimate(Episode episode) {
  if (!episode.isLive) return 0;
  final base = 120 + (episode.durationSec ?? 45);
  final sentiment = (episode.keywords?.length ?? 1) * 15;
  final random = (episode.id.hashCode.abs() % 120);
  return base + sentiment + random;
}
