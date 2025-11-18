import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/explore.dart';
import '../../data/repositories/explore_repository.dart';
import 'session_provider.dart';

final exploreFeedProvider =
    StateNotifierProvider<ExploreFeedNotifier, ExploreFeedState>(
  (ref) => ExploreFeedNotifier(ref),
);

class ExploreFeedState {
  const ExploreFeedState({
    required this.cards,
    required this.nextCursor,
    required this.isLoading,
    required this.isLoadingMore,
    required this.filters,
    this.error,
  });

  factory ExploreFeedState.initial() => ExploreFeedState(
        cards: const [],
        nextCursor: null,
        isLoading: false,
        isLoadingMore: false,
        filters: const ExploreFilters(),
      );

  final List<ExploreCard> cards;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final ExploreFilters filters;
  final Object? error;

  bool get hasMore => nextCursor != null;

  ExploreFeedState copyWith({
    List<ExploreCard>? cards,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    ExploreFilters? filters,
    Object? error = _noError,
  }) {
    return ExploreFeedState(
      cards: cards ?? this.cards,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filters: filters ?? this.filters,
      error: error == _noError ? this.error : error,
    );
  }

  static const _noError = Object();
}

class ExploreFeedNotifier extends StateNotifier<ExploreFeedState> {
  ExploreFeedNotifier(this._ref) : super(ExploreFeedState.initial());

  final Ref _ref;
  static const _pageSize = 20;

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, nextCursor: null);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    await _loadPage(reset: false);
  }

  void toggleTag(String tag) {
    final normalized = tag.toLowerCase();
    final tags = Set<String>.from(state.filters.tags);
    if (tags.contains(normalized)) {
      tags.remove(normalized);
    } else {
      tags.add(normalized);
    }
    state = state.copyWith(
      filters: state.filters.copyWith(tags: tags),
    );
    refresh();
  }

  void setLengthFilter(ExploreLengthFilter filter) {
    if (state.filters.length == filter) return;
    state = state.copyWith(filters: state.filters.copyWith(length: filter));
    refresh();
  }

  Future<void> _loadPage({required bool reset}) async {
    final repo = _ref.read(exploreRepositoryProvider);
    final session = _ref.read(sessionProvider);
    try {
      final filters = state.filters;
      final page = await repo.fetchExploreFeed(
        token: session.token,
        limit: _pageSize,
        cursor: reset ? null : state.nextCursor,
        tags: filters.tags.toList(),
        minLength: filters.length.minSeconds,
        maxLength: filters.length.maxSeconds,
      );
      final data = reset ? page.cards : [...state.cards, ...page.cards];
      state = state.copyWith(
        cards: data,
        nextCursor: page.nextCursor,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (error, stack) {
      AppLogger.error(
        'Explore fetch failed',
        tag: 'ExploreProvider',
        error: error,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }
}

class ExploreFilters {
  const ExploreFilters({
    this.tags = const {},
    this.length = ExploreLengthFilter.any,
  });

  final Set<String> tags;
  final ExploreLengthFilter length;

  ExploreFilters copyWith({
    Set<String>? tags,
    ExploreLengthFilter? length,
  }) {
    return ExploreFilters(
      tags: tags ?? this.tags,
      length: length ?? this.length,
    );
  }
}

enum ExploreLengthFilter {
  any,
  shorts,
  medium,
  long,
}

extension ExploreLengthFilterRange on ExploreLengthFilter {
  int? get minSeconds {
    switch (this) {
      case ExploreLengthFilter.any:
        return null;
      case ExploreLengthFilter.shorts:
        return 0;
      case ExploreLengthFilter.medium:
        return 120;
      case ExploreLengthFilter.long:
        return 600;
    }
  }

  int? get maxSeconds {
    switch (this) {
      case ExploreLengthFilter.any:
        return null;
      case ExploreLengthFilter.shorts:
        return 180;
      case ExploreLengthFilter.medium:
        return 600;
      case ExploreLengthFilter.long:
        return null;
    }
  }
}

const _defaultExploreTags = <String>[
  'ai',
  'founders',
  'product',
  'design',
  'cities',
  'wellness',
  'news',
];

final exploreTagSuggestionsProvider = Provider<List<String>>((ref) {
  return _defaultExploreTags;
});
