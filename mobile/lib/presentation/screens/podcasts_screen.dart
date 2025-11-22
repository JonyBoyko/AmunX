import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../providers/feed_provider.dart';
import '../providers/author_directory_provider.dart';
import '../providers/reaction_provider.dart';
import '../widgets/episode_card.dart';
import '../widgets/glitch_logo_symbol.dart';

class PodcastsScreen extends ConsumerWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header з пошуком
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  const GlitchLogoSymbol(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.glassSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.glassStroke),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                          SizedBox(width: 8),
                          Text('Пошук подкастів...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Список подкастів (фільтруємо тільки podcast_episode kind)
            Expanded(
              child: feedAsync.when(
                data: (episodes) {
                  // TODO: фільтр тільки podcast_episode
                  final podcasts = episodes.where((e) => (e.durationSec ?? 0) > 180).toList();
                  
                  if (podcasts.isEmpty) {
                    return const Center(
                      child: Text('Немає подкастів', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(feedProvider.future),
                    color: AppTheme.brandPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: podcasts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final episode = podcasts[index];
                        final authors = ref.watch(authorDirectoryProvider);
                        final author = authors[episode.authorId];
                        final reactionSnapshot = ref.watch(reactionSnapshotProvider(episode.id));

                        return EpisodeCard(
                          episode: episode,
                          author: author,
                          reactionSnapshot: reactionSnapshot,
                          onTap: () {},
                          onReactionTap: (type) async {
                            await ref.read(reactionProvider.notifier).toggleReaction(episode.id, type);
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text('Помилка завантаження', style: TextStyle(color: AppTheme.stateDanger)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


