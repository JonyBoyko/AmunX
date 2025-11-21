import 'dart:ui';

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
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -100,
            top: 40,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -60,
            child: Opacity(
              opacity: 0.14,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: _GlassPanel(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search transcripts, titles, tags...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.neonBlue),
                      suffixIcon: searchState.query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchProvider.notifier).search('');
                              },
                              icon: const Icon(Icons.close,
                                  color: AppTheme.textSecondary),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.glassSurfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: AppTheme.glassStroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: AppTheme.glassStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: AppTheme.neonBlue),
                      ),
                    ),
                  ),
                ),
              ),
              if (searchState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                  child: CircularProgressIndicator(color: AppTheme.neonBlue),
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
                                  child: CircularProgressIndicator(
                                    color: AppTheme.neonBlue,
                                  ),
                                ),
                              );
                            }
                            if (searchState.canLoadMore) {
                              return _GlassPanel(
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
        child: _GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, color: AppTheme.neonBlue, size: 32),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
    return _GlassPanel(
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
                    backgroundColor: AppTheme.glassSurfaceLight,
                    child: Text(
                      result.owner.displayName.isEmpty
                          ? '?'
                          : result.owner.displayName.characters.first,
                      style: const TextStyle(color: AppTheme.neonBlue),
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
                            fontWeight: FontWeight.w700,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.glassStroke),
                    ),
                    child: Text(
                      '${(result.matchScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.neonBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                result.snippet.isEmpty
                    ? 'No snippet'
                    : result.snippet.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              if (result.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: result.tags
                      .map(
                        (tag) => Chip(
                          label: Text('#$tag'),
                          side: const BorderSide(color: AppTheme.glassStroke),
                          backgroundColor: AppTheme.glassSurfaceLight,
                          labelStyle: const TextStyle(color: AppTheme.textPrimary),
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurMd,
          sigmaY: AppTheme.blurMd,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
