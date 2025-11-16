import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../providers/feed_provider.dart';
import '../widgets/episode_card.dart';
import '../widgets/mini_player_bar.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  Episode? _playingEpisode;

  Future<void> _openEpisode(Episode episode) {
    return context.push('/episode/${episode.id}');
  }

  void _openTopic(Episode episode) {
    final topic = episode.keywords?.first ?? 'general';
    context.push('/topic/${Uri.encodeComponent(topic)}');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building FeedScreen', tag: 'Feed');
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider.future),
              color: AppTheme.brandPrimary,
              child: feedAsync.when(
                data: (episodes) => _buildFeed(context, episodes),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildError(context),
              ),
            ),
            Positioned(
              right: 16,
              bottom: _playingEpisode != null ? 96 : 24,
              child: _RecordFab(
                onTap: () => context.push('/recorder'),
              ),
            ),
            if (_playingEpisode != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayerBar(
                  episode: _playingEpisode!,
                  onPause: () => setState(() => _playingEpisode = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, List<Episode> episodes) {
    if (episodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Стрічка порожня',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/recorder'),
              child: const Text('Записати перший епізод'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _FeedHeader(onProfileTap: () => context.push('/profile'))),
        SliverList.separated(
          itemCount: episodes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return EpisodeCard(
              episode: episode,
              onTap: () => _openEpisode(episode),
              onTopicTap: () => _openTopic(episode),
            );
          },
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: _playingEpisode != null ? 160 : 120),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Щось пішло не так',
            style: TextStyle(color: AppTheme.stateDanger),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.refresh(feedProvider),
            child: const Text('Спробувати ще раз'),
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _FeedHeader({
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceLg,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Moweton',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Голосові щоденники & Live-кімнати',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onProfileTap,
            icon: const Icon(Icons.person_outline, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RecordFab extends StatelessWidget {
  final VoidCallback onTap;

  const _RecordFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.brandPrimary, AppTheme.brandAccent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: AppTheme.textInverse),
      ),
    );
  }
}

