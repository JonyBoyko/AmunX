import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../filters/feed_filters.dart';

class FeedFilterNotifier extends StateNotifier<FeedFilterState> {
  FeedFilterNotifier() : super(FeedFilterState.initial());

  void setTab(FeedTab tab) {
    final nextRegion =
        tab == FeedTab.trendingNearby ? RegionFilter.nearby : state.region;
    state = state.copyWith(tab: tab, region: nextRegion);
    AppLogger.debug(
      'Feed tab switched to ${tab.name}',
      tag: 'FeedFilter',
    );
  }

  void setFormat(ContentFormat format) {
    state = state.copyWith(format: format);
    AppLogger.debug(
      'Feed format switched to ${format.name}',
      tag: 'FeedFilter',
    );
  }

  void setRegion(RegionFilter region) {
    state = state.copyWith(region: region);
    AppLogger.debug(
      'Region filter switched to ${region.name}',
      tag: 'FeedFilter',
    );
  }

  void toggleTag(String tagLabel) {
    final normalized = tagLabel.trim().toLowerCase();
    final current = state.selectedTags.toSet();
    if (current.contains(normalized)) {
      current.remove(normalized);
    } else {
      current.add(normalized);
    }
    state = state.copyWith(selectedTags: current);
    AppLogger.debug(
      'Tag filter updated: ${state.selectedTags.join(', ')}',
      tag: 'FeedFilter',
    );
  }

  void applySmartInboxFilter(String tagLabel) {
    final normalized = tagLabel.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    state = state.copyWith(
      tab: FeedTab.recommended,
      region: RegionFilter.global,
      selectedTags: <String>{normalized},
    );
    AppLogger.debug(
      'Smart Inbox quick filter applied: #$normalized',
      tag: 'FeedFilter',
    );
  }

  void clearTags() {
    if (state.selectedTags.isEmpty) return;
    state = state.copyWith(selectedTags: <String>{});
    AppLogger.debug(
      'Tag filters cleared',
      tag: 'FeedFilter',
    );
  }
}

final feedFilterProvider =
    StateNotifierProvider<FeedFilterNotifier, FeedFilterState>(
  (ref) => FeedFilterNotifier(),
);
