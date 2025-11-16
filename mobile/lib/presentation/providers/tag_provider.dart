import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_tag.dart';

class TrendingTagsNotifier extends StateNotifier<List<FeedTag>> {
  TrendingTagsNotifier() : super(defaultFeedTags);

  void toggleFollow(String label) {
    state = [
      for (final tag in state)
        if (tag.label == label)
          tag.copyWith(isFollowed: !tag.isFollowed)
        else
          tag,
    ];
  }
}

final trendingTagsProvider =
    StateNotifierProvider<TrendingTagsNotifier, List<FeedTag>>(
  (ref) => TrendingTagsNotifier(),
);
