import 'package:flutter_test/flutter_test.dart';

import 'package:moweton_flutter/presentation/filters/feed_filters.dart';
import 'package:moweton_flutter/presentation/providers/feed_filter_provider.dart';

void main() {
  group('FeedFilterNotifier', () {
    test('toggleTag normalizes labels and toggles membership', () {
      final notifier = FeedFilterNotifier();

      notifier.toggleTag('AI ');
      expect(notifier.state.selectedTags.contains('ai'), isTrue);

      notifier.toggleTag('AI');
      expect(notifier.state.selectedTags, isEmpty);
    });

    test('applySmartInboxFilter resets to recommended/global with single tag',
        () {
      final notifier = FeedFilterNotifier()
        ..setTab(FeedTab.trendingNearby)
        ..setRegion(RegionFilter.europe)
        ..toggleTag('news')
        ..toggleTag('ai');

      notifier.applySmartInboxFilter('Climate');

      expect(notifier.state.tab, FeedTab.recommended);
      expect(notifier.state.region, RegionFilter.global);
      expect(notifier.state.selectedTags.length, 1);
      expect(notifier.state.selectedTags.contains('climate'), isTrue);
    });
  });
}
