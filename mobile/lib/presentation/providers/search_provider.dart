import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/search.dart';
import '../../data/repositories/search_repository.dart';
import 'session_provider.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});

class SearchState {
  const SearchState({
    required this.query,
    required this.results,
    required this.total,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasSearched,
    required this.searchType,
    this.error,
  });

  factory SearchState.initial() => const SearchState(
        query: '',
        results: [],
        total: 0,
        isLoading: false,
        isLoadingMore: false,
        hasSearched: false,
        searchType: 'text',
      );

  final String query;
  final List<SearchResult> results;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasSearched;
  final String searchType;
  final Object? error;

  bool get canLoadMore => results.length < total;

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasSearched,
    String? searchType,
    Object? error = _noError,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasSearched: hasSearched ?? this.hasSearched,
      searchType: searchType ?? this.searchType,
      error: error == _noError ? this.error : error,
    );
  }

  static const _noError = Object();
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._ref) : super(SearchState.initial());

  final Ref _ref;
  static const _pageSize = 20;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(
        query: trimmed,
        hasSearched: trimmed.isNotEmpty,
        results: [],
        total: 0,
      );
      return;
    }
    state = state.copyWith(
      query: trimmed,
      isLoading: true,
      hasSearched: true,
      error: null,
    );
    await _executeSearch(offset: 0, append: false);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.canLoadMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    await _executeSearch(offset: state.results.length, append: true);
  }

  Future<void> _executeSearch({
    required int offset,
    required bool append,
  }) async {
    final repo = _ref.read(searchRepositoryProvider);
    final session = _ref.read(sessionProvider);
    try {
      final response = await repo.searchAudio(
        query: state.query,
        token: session.token,
        limit: _pageSize,
        offset: offset,
      );
      final merged = append
          ? [...state.results, ...response.results]
          : response.results;
      state = state.copyWith(
        results: merged,
        total: response.total,
        searchType: response.searchType,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (error, stack) {
      AppLogger.error(
        'Search failed',
        tag: 'SearchProvider',
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

