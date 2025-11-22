import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../filters/feed_filters.dart';
import '../models/feed_tag.dart';
import '../models/live_room.dart';
import '../providers/author_directory_provider.dart';
import '../providers/feed_filter_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/live_rooms_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/reaction_provider.dart';
import '../services/live_notification_service.dart';
import '../providers/smart_inbox_provider.dart';
import '../utils/feed_classifiers.dart';
import '../widgets/episode_card.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/wave_tag_chip.dart';
import '../widgets/glitch_logo_symbol.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  Episode? _playingEpisode;

  Future<void> _openEpisode(Episode episode) async {
    setState(() => _playingEpisode = episode);
    await context.push('/episode/${episode.id}');
  }

  void _openTopic(Episode episode) {
    final topic = episode.keywords?.first ?? 'general';
    context.push('/topic/${Uri.encodeComponent(topic)}');
  }

  Future<void> _handleReactionTap(Episode episode, String type) async {
    try {
      await ref.read(reactionProvider.notifier).toggleReaction(
            episode.id,
            type,
          );
    } on StateError {
      if (!mounted) return;
      _showSnack('Reaction already applied. Try another.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to update reactions. Please retry.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building FeedScreen', tag: 'Feed');
    final feedAsync = ref.watch(feedProvider);
    final filterState = ref.watch(feedFilterProvider);
    final tags = ref.watch(trendingTagsProvider);
    final liveRooms = ref.watch(liveRoomsProvider);
    final liveNotification = ref.watch(liveNotificationProvider);
    final smartInboxAsync = ref.watch(smartInboxProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
            ),
            if (liveNotification != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _LiveNotificationBanner(notification: liveNotification),
              ),
            RefreshIndicator(
              onRefresh: () => Future.wait([
                ref.refresh(feedProvider.future),
                ref.refresh(smartInboxProvider.future),
              ]),
              color: AppTheme.brandPrimary,
              child: feedAsync.when(
                data: (episodes) {
                  AppLogger.debug('FeedScreen: episodes count = ${episodes.length}', tag: 'Feed');
                  return _buildFeed(
                    context,
                    episodes,
                    filterState,
                    tags,
                    liveRooms,
                    smartInboxAsync,
                  );
                },
                loading: () {
                  AppLogger.debug('FeedScreen: loading', tag: 'Feed');
                  return const Center(child: CircularProgressIndicator());
                },
                error: (error, stack) {
                  AppLogger.error('FeedScreen: error', tag: 'Feed', error: error, stackTrace: stack);
                  return _buildError(context);
                },
              ),
            ),
            // TODO: додати тумблер режиму запису (звичайний голосовий / broadcast podcast)
            Positioned(
              right: 16,
              bottom: _playingEpisode != null ? 100 : 80,
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

  Widget _buildFeed(
    BuildContext context,
    List<Episode> episodes,
    FeedFilterState filters,
    List<FeedTag> tags,
    List<LiveRoom> liveRooms,
    AsyncValue<SmartInboxState> smartInboxAsync,
  ) {
    // Delay provider modification until after build
    Future(() {
      ref.read(authorDirectoryProvider.notifier).syncWithEpisodes(episodes);
    });
    final authors = ref.watch(authorDirectoryProvider);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _FeedHeader(
            onProfileTap: () => context.push('/profile'),
            onInboxTap: () => context.push('/inbox'),
          ),
        ),
        if (episodes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyFeed(onRecord: () => context.push('/recorder')),
          )
        else
          SliverList.separated(
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final region = deriveRegion(episode);
              final format = classifyFormat(episode);
              final author = authors[episode.authorId];
              final liveListeners = liveAudienceEstimate(episode);
              final reactionSnapshot =
                  ref.watch(reactionSnapshotProvider(episode.id));
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                  vertical: 4,
                ),
                child: EpisodeCard(
                  episode: episode,
                  regionLabel: region.label,
                  formatLabel: format.label,
                  author: author,
                  liveListeners: liveListeners > 0 ? liveListeners : null,
                  onFollowToggle: author == null
                      ? null
                      : () => ref
                          .read(authorDirectoryProvider.notifier)
                          .toggleFollow(author.id),
                  onTap: () => _openEpisode(episode),
                  onTopicTap: () => _openTopic(episode),
                  reactionSnapshot: reactionSnapshot,
                  onReactionTap: (type) => _handleReactionTap(episode, type),
                ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Something went wrong loading your feed.',
                style: TextStyle(color: AppTheme.stateDanger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              FilledButton(
                onPressed: () => ref.refresh(feedProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onRecord;

  const _EmptyFeed({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.glassStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nothing in your feed yet.',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            const Text(
              'Follow more creators or tweak filters to see fresh episodes tailored for you.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton(
              onPressed: onRecord,
              child: const Text('Start recording'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onInboxTap;

  const _FeedHeader({
    required this.onProfileTap,
    required this.onInboxTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (left)
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonBlue.withValues(alpha: 0.2),
                border: Border.all(color: AppTheme.neonBlue, width: 2),
              ),
              child: const Icon(Icons.person, color: AppTheme.neonBlue, size: 20),
            ),
          ),
          // GlitchLogo symbol (center)
          const GlitchLogoSymbol(size: 36),
          // AI Digest icon (right)
          IconButton(
            tooltip: 'AI Digest',
            onPressed: onInboxTap,
            icon: const Icon(Icons.auto_awesome, color: AppTheme.neonPurple, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _LiveNotificationBanner extends StatelessWidget {
  const _LiveNotificationBanner({required this.notification});

  final LiveNotification notification;

  String _relativeLabel() {
    final minutes = DateTime.now().difference(notification.createdAt).inMinutes;
    if (minutes <= 0) return 'Just now';
    if (minutes < 60) return '${minutes}m ago';
    final hours = (minutes / 60).floor();
    return '${hours}h ago';
  }

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
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: AppTheme.glowPrimary,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                  boxShadow: AppTheme.glowPrimary,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.textInverse,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSm,
                  vertical: AppTheme.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassSurfaceDense,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.glassStroke),
                ),
                child: Text(
                  _relativeLabel(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SmartInboxPreview extends StatelessWidget {
  const _SmartInboxPreview({
    required this.digest,
    required this.highlights,
    required this.onOpenEpisode,
    required this.onOpenInbox,
    required this.onTagSelected,
  });

  final SmartInboxDigest digest;
  final List<String> highlights;
  final ValueChanged<String> onOpenEpisode;
  final VoidCallback onOpenInbox;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final entries = digest.entries.take(2).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurMd,
          sigmaY: AppTheme.blurMd,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, 18),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: AppTheme.glowPrimary,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppTheme.textInverse,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI digest',
                          style: TextStyle(
                            color: AppTheme.textInverse,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onOpenInbox,
                    icon: const Icon(Icons.inbox, color: AppTheme.brandPrimary),
                    label: const Text('Open inbox'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              if (digest.summary.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurfaceDense,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.glassStroke),
                  ),
                  child: Text(
                    digest.summary,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: highlights
                      .map(
                        (tag) => _TagPill(
                          label: '#$tag',
                          onTap: () => onTagSelected(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppTheme.spaceMd),
              ...entries.map(
                (entry) => _SmartInboxEntryCard(
                  entry: entry,
                  onOpenEpisode: onOpenEpisode,
                  onTagSelected: onTagSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartInboxEntryCard extends StatelessWidget {
  const _SmartInboxEntryCard({
    required this.entry,
    required this.onOpenEpisode,
    required this.onTagSelected,
  });

  final SmartInboxEntry entry;
  final ValueChanged<String> onOpenEpisode;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpenEpisode(entry.episodeId),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceDense,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.glassStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (entry.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: AppTheme.glowPrimary,
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: AppTheme.textInverse,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              entry.snippet,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Wrap(
                spacing: AppTheme.spaceSm,
                runSpacing: AppTheme.spaceSm,
                children: entry.tags
                    .map(
                      (tag) => _TagPill(
                        label: '#$tag',
                        dense: true,
                        onTap: () => onTagSelected(tag),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SmartInboxPlaceholder extends StatelessWidget {
  const _SmartInboxPlaceholder();

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
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Container(
                width: double.infinity,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SmartInboxErrorCard extends StatelessWidget {
  const _SmartInboxErrorCard({required this.onRetry});

  final VoidCallback onRetry;

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
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.stateDanger,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  const Text(
                    'Could not load AI digest',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'Check your connection and try again.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FormatSwitchBar extends StatelessWidget {
  const _FormatSwitchBar({
    required this.selected,
    required this.onSelected,
  });

  final ContentFormat selected;
  final ValueChanged<ContentFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blurSm,
            sigmaY: AppTheme.blurSm,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceSm),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppTheme.glassStroke),
            ),
            child: Row(
              children: ContentFormat.values
                  .map(
                    (format) => Expanded(
                      child: _SegmentChip(
                        label: format.label,
                        description: format.description,
                        active: selected == format,
                        onTap: () => onSelected(format),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.description,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandPrimary.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: active ? AppTheme.brandPrimary : AppTheme.glassStroke,
          ),
          boxShadow: active ? AppTheme.glowPrimary : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.brandPrimary : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LiveNowStrip extends StatelessWidget {
  const _LiveNowStrip({
    required this.rooms,
    required this.onRoomTap,
    required this.onFollowToggle,
  });

  final List<LiveRoom> rooms;
  final ValueChanged<LiveRoom> onRoomTap;
  final ValueChanged<LiveRoom> onFollowToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.circle_rounded, color: AppTheme.neonPink),
              SizedBox(width: AppTheme.spaceSm),
              Text(
                'Circle',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rooms.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spaceSm),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return _LiveRoomCard(
                  room: room,
                  onTap: () => onRoomTap(room),
                  onFollowToggle: () => onFollowToggle(room),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({
    required this.room,
    required this.onTap,
    required this.onFollowToggle,
  });

  final LiveRoom room;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  // Визначаємо колір кімнати на основі ID (для різноманітності)
  Color _getRoomColor() {
    final hash = room.id.hashCode;
    final index = hash.abs() % 3;
    switch (index) {
      case 0:
        return AppTheme.neonBlue;
      case 1:
        return AppTheme.neonPurple;
      case 2:
        return AppTheme.neonPink;
      default:
        return AppTheme.neonBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(room.startedAt).inMinutes;
    final elapsedLabel = elapsed < 1 ? 'live now' : '${elapsed}m live';
    final roomColor = _getRoomColor();
    final hasUnread = room.listeners > 0; // Можна додати логіку для unread

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: hasUnread
                ? roomColor.withValues(alpha: 0.3)
                : AppTheme.glassStroke,
          ),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: roomColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  const BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                    spreadRadius: -6,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                    spreadRadius: -6,
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Unread indicator (ліва лінія) - згідно з макетом
            if (hasUnread)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: roomColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSm,
                        vertical: AppTheme.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.neonGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        boxShadow: AppTheme.glowPink,
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.textInverse,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Text(
                      elapsedLabel,
                      style: TextStyle(
                        color: hasUnread
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onFollowToggle,
                      icon: Icon(
                        room.isFollowedHost
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: room.isFollowedHost
                            ? AppTheme.neonPink
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: roomColor.withValues(alpha: 0.2),
                        border: Border.all(
                          color: roomColor,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        room.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? AppTheme.textPrimary
                                  : AppTheme.textPrimary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${room.handle.isNotEmpty ? room.handle : room.hostName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          // WaveTags
                          if (room.tags.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            WaveTagList(
                              tags: room.tags,
                              maxVisible: 2,
                              variant: roomColor == AppTheme.neonBlue
                                  ? WaveTagVariant.cyan
                                  : roomColor == AppTheme.neonPurple
                                      ? WaveTagVariant.purple
                                      : WaveTagVariant.pink,
                              size: WaveTagSize.sm,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 14,
                      color: roomColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.listeners}',
                      style: TextStyle(
                        color: roomColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: AppTheme.spaceMd),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roomColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: roomColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 12,
                              color: roomColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'нових',
                              style: TextStyle(
                                color: roomColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.filters,
    required this.tags,
    required this.onTabSelected,
    required this.onFormatSelected,
    required this.onRegionSelected,
    required this.onTagToggled,
    required this.onClearTags,
  });

  final FeedFilterState filters;
  final List<FeedTag> tags;
  final ValueChanged<FeedTab> onTabSelected;
  final ValueChanged<ContentFormat> onFormatSelected;
  final ValueChanged<RegionFilter> onRegionSelected;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClearTags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blurMd,
            sigmaY: AppTheme.blurMd,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppTheme.glassStroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (filters.selectedTags.isNotEmpty)
                      TextButton(
                        onPressed: onClearTags,
                        child: const Text('Clear tags'),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: FeedTab.values
                      .map(
                        (tab) => _TogglePill(
                          label: tab.label,
                          active: filters.tab == tab,
                          onTap: () => onTabSelected(tab),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: RegionFilter.values
                      .map(
                        (region) => _TogglePill(
                          label: region.label,
                          active: filters.region == region,
                          onTap: () => onRegionSelected(region),
                          subtle: true,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ContentFormat.values
                        .map(
                          (format) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppTheme.spaceSm),
                            child: _TogglePill(
                              label: format.label,
                              active: filters.format == format,
                              onTap: () => onFormatSelected(format),
                              subtle: true,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Text(
                  'Trending tags',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: tags
                      .map(
                        (tag) => _TagPill(
                          label:
                              '${tag.emoji.isNotEmpty ? '${tag.emoji} ' : ''}${tag.label}',
                          active: filters.selectedTags
                              .contains(tag.label.toLowerCase()),
                          onTap: () => onTagToggled(tag.label),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.active,
    required this.onTap,
    this.subtle = false,
  });

  final String label;
  final bool active;
  final bool subtle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(0.14)
              : (subtle ? AppTheme.bgMuted : AppTheme.glassSurfaceDense),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: active ? AppTheme.brandPrimary : AppTheme.glassStroke,
          ),
          boxShadow: active ? AppTheme.glowPrimary : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.brandPrimary : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.onTap,
    this.active = false,
    this.dense = false,
  });

  final String label;
  final bool active;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppTheme.spaceSm : AppTheme.spaceMd,
          vertical: dense ? AppTheme.spaceXs : AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandPrimary.withOpacity(0.14)
              : AppTheme.glassSurfaceDense,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: active ? AppTheme.brandPrimary : AppTheme.glassStroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.brandPrimary : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: dense ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FeedTabBar extends StatelessWidget {
  final TabController controller;

  const _FeedTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        border: Border(bottom: BorderSide(color: AppTheme.glassStroke)),
      ),
      child: TabBar(
        controller: controller,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.neonBlue, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        tabs: const [
          Tab(text: 'Для вас'),
          Tab(text: 'Підписки'),
        ],
      ),
    );
  }
}

class _RecordFab extends StatelessWidget {
  const _RecordFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          gradient: AppTheme.neonGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.glowAccent,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.bgBase,
          ),
          child: const Icon(
            Icons.mic,
            color: AppTheme.textPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
