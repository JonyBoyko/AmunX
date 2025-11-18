import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/search.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    ref.read(searchProvider.notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppTheme.bgBase,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search transcripts, titles, tags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchState.query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).search('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (searchState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: searchState.results.isEmpty
                ? _SearchPlaceholder(
                    hasSearched: searchState.hasSearched,
                    query: searchState.query,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spaceLg,
                      right: AppTheme.spaceLg,
                      bottom: AppTheme.spaceLg,
                    ),
                    itemCount: searchState.results.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spaceSm),
                    itemBuilder: (context, index) {
                      if (index == searchState.results.length) {
                        if (searchState.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppTheme.spaceSm,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (searchState.canLoadMore) {
                          return Center(
                            child: TextButton(
                              onPressed: () =>
                                  ref.read(searchProvider.notifier).loadMore(),
                              child: const Text('Load more'),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final result = searchState.results[index];
                      return _SearchResultTile(
                        result: result,
                        onTap: () => context.push('/episode/${result.audioId}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({
    required this.hasSearched,
    required this.query,
  });

  final bool hasSearched;
  final String query;

  @override
  Widget build(BuildContext context) {
    final text = hasSearched && query.isNotEmpty
        ? 'No matches for "$query"'
        : 'Search across transcripts and descriptions';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.onTap,
  });

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.bgRaised,
                    child: Text(
                      result.owner.displayName.isEmpty
                          ? '?'
                          : result.owner.displayName.characters.first,
                      style: const TextStyle(color: AppTheme.brandPrimary),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${result.owner.displayName} • ${_formatDuration(result.durationSec)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(result.matchScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                result.snippet.isEmpty
                    ? 'No snippet'
                    : result.snippet.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              if (result.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  children: result.tags
                      .map(
                        (tag) => Chip(
                          label: Text('#$tag'),
                          backgroundColor: AppTheme.bgRaised,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = (seconds / 60).floor();
  final secs = seconds % 60;
  if (minutes <= 0) {
    return '${secs}s';
  }
  if (minutes < 60) {
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }
  final hours = (minutes / 60).floor();
  final restMinutes = minutes % 60;
  return '${hours}h ${restMinutes}m';
}
