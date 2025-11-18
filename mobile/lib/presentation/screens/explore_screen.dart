import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../providers/explore_provider.dart';
import '../widgets/explore_card_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(exploreFeedProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreFeedProvider);
    final tags = ref.watch(exploreTagSuggestionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: AppTheme.bgBase,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(exploreFeedProvider.notifier).refresh(forceNetwork: true),
        color: AppTheme.brandPrimary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                  vertical: AppTheme.spaceMd,
                ),
                child: _ExploreFilters(
                  state: exploreState,
                  suggestions: tags,
                  onTagToggled: (tag) =>
                      ref.read(exploreFeedProvider.notifier).toggleTag(tag),
                  onLengthSelected: (filter) =>
                      ref.read(exploreFeedProvider.notifier).setLengthFilter(
                            filter,
                          ),
                ),
              ),
            ),
            if (exploreState.isLoading && exploreState.cards.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (exploreState.cards.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyExploreState(
                  onSearchTap: () => context.push('/search'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = exploreState.cards[index];
                    return ExploreCardTile(
                      card: card,
                      onTap: () => context.push('/episode/${card.id}'),
                      onTagSelected: (tag) =>
                          ref.read(exploreFeedProvider.notifier).toggleTag(tag),
                    );
                  },
                  childCount: exploreState.cards.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                  vertical: AppTheme.spaceLg,
                ),
                child: Column(
                  children: [
                    if (exploreState.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    else if (exploreState.hasMore)
                      FilledButton(
                        onPressed: () =>
                            ref.read(exploreFeedProvider.notifier).loadMore(),
                        child: const Text('Load more'),
                      ),
                    if (exploreState.error != null)
                      const Padding(
                        padding: EdgeInsets.only(top: AppTheme.spaceSm),
                        child: Text(
                          'Failed to load explore feed',
                          style: TextStyle(color: AppTheme.stateDanger),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreFilters extends StatelessWidget {
  const _ExploreFilters({
    required this.state,
    required this.suggestions,
    required this.onTagToggled,
    required this.onLengthSelected,
  });

  final ExploreFeedState state;
  final List<String> suggestions;
  final ValueChanged<String> onTagToggled;
  final ValueChanged<ExploreLengthFilter> onLengthSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Length',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Wrap(
          spacing: AppTheme.spaceSm,
          children: ExploreLengthFilter.values.map((filter) {
            final isSelected = state.filters.length == filter;
            return ChoiceChip(
              label: Text(_labelForFilter(filter)),
              selected: isSelected,
              onSelected: (_) => onLengthSelected(filter),
              selectedColor: AppTheme.brandPrimary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        const Text(
          'Trending tags',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Wrap(
          spacing: AppTheme.spaceSm,
          runSpacing: AppTheme.spaceSm,
          children: suggestions.map((tag) {
            final normalized = tag.toLowerCase();
            final isSelected = state.filters.tags.contains(normalized);
            return FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (_) => onTagToggled(tag),
              selectedColor: AppTheme.brandAccent.withValues(alpha: 0.2),
              side: BorderSide(
                color:
                    isSelected ? AppTheme.brandAccent : AppTheme.surfaceBorder,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _labelForFilter(ExploreLengthFilter filter) {
    switch (filter) {
      case ExploreLengthFilter.any:
        return 'Any';
      case ExploreLengthFilter.shorts:
        return '< 3 min';
      case ExploreLengthFilter.medium:
        return '3-10 min';
      case ExploreLengthFilter.long:
        return 'Long form';
    }
  }
}

class _EmptyExploreState extends StatelessWidget {
  const _EmptyExploreState({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nothing to explore yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Try another filter or run a search over transcripts.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          OutlinedButton(
            onPressed: onSearchTap,
            child: const Text('Open search'),
          ),
        ],
      ),
    );
  }
}
