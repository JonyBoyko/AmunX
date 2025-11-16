import 'dart:collection';

import 'package:flutter/foundation.dart';

enum FeedTab {
  subscriptions,
  all,
  recommended,
  trendingNearby,
}

extension FeedTabX on FeedTab {
  String get label {
    switch (this) {
      case FeedTab.subscriptions:
        return 'Підписки';
      case FeedTab.all:
        return 'Всі';
      case FeedTab.recommended:
        return 'Рекомендовані';
      case FeedTab.trendingNearby:
        return 'Тренди поруч';
    }
  }

  String get queryValue {
    switch (this) {
      case FeedTab.subscriptions:
        return 'subscriptions';
      case FeedTab.all:
        return 'all';
      case FeedTab.recommended:
        return 'recommended';
      case FeedTab.trendingNearby:
        return 'trending_nearby';
    }
  }
}

enum ContentFormat {
  shorts,
  podcasts,
  live,
}

extension ContentFormatX on ContentFormat {
  String get label {
    switch (this) {
      case ContentFormat.shorts:
        return 'Короткі';
      case ContentFormat.podcasts:
        return 'Подкасти';
      case ContentFormat.live:
        return 'Live';
    }
  }

  String get description {
    switch (this) {
      case ContentFormat.shorts:
        return 'до 2 хв';
      case ContentFormat.podcasts:
        return 'довгі / записи';
      case ContentFormat.live:
        return 'прямі ефіри';
    }
  }
}

enum RegionFilter {
  global,
  nearby,
  europe,
  northAmerica,
}

extension RegionFilterX on RegionFilter {
  String get label {
    switch (this) {
      case RegionFilter.global:
        return 'Глобально';
      case RegionFilter.nearby:
        return 'Поруч (Київ)';
      case RegionFilter.europe:
        return 'Європа';
      case RegionFilter.northAmerica:
        return 'Півн. Америка';
    }
  }

  String get queryValue {
    switch (this) {
      case RegionFilter.global:
        return 'global';
      case RegionFilter.nearby:
        return 'nearby';
      case RegionFilter.europe:
        return 'eu';
      case RegionFilter.northAmerica:
        return 'na';
    }
  }
}

@immutable
class FeedFilterState {
  final FeedTab tab;
  final ContentFormat format;
  final RegionFilter region;
  final UnmodifiableSetView<String> selectedTags;

  FeedFilterState({
    this.tab = FeedTab.all,
    this.format = ContentFormat.shorts,
    this.region = RegionFilter.global,
    Set<String>? selectedTags,
  }) : selectedTags = UnmodifiableSetView<String>(selectedTags ?? <String>{});

  factory FeedFilterState.initial() => FeedFilterState();

  FeedFilterState copyWith({
    FeedTab? tab,
    ContentFormat? format,
    RegionFilter? region,
    Set<String>? selectedTags,
  }) {
    return FeedFilterState(
      tab: tab ?? this.tab,
      format: format ?? this.format,
      region: region ?? this.region,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'feed_tab': tab.queryValue,
      'format': format.name,
      'region': region.queryValue,
    };

    if (selectedTags.isNotEmpty) {
      params['tags'] = selectedTags.join(',');
    }

    return params;
  }
}
