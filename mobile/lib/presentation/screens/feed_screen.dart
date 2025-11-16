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
import '../services/live_notification_service.dart';
import '../utils/feed_classifiers.dart';
import '../widgets/episode_card.dart';
import '../widgets/mini_player_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building FeedScreen', tag: 'Feed');
    final feedAsync = ref.watch(feedProvider);
    final filterState = ref.watch(feedFilterProvider);
    final tags = ref.watch(trendingTagsProvider);
    final liveRooms = ref.watch(liveRoomsProvider);
    final liveNotification = ref.watch(liveNotificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            if (liveNotification != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _LiveNotificationBanner(notification: liveNotification),
              ),
            RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider.future),
              color: AppTheme.brandPrimary,
              child: feedAsync.when(
                data: (episodes) => _buildFeed(
                  context,
                  episodes,
                  filterState,
                  tags,
                  liveRooms,
                ),
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

  Widget _buildFeed(
    BuildContext context,
    List<Episode> episodes,
    FeedFilterState filters,
    List<FeedTag> tags,
    List<LiveRoom> liveRooms,
  ) {
    final coverageNotifier = ref.read(feedFilterProvider.notifier);
    final tagsNotifier = ref.read(trendingTagsProvider.notifier);
    ref.read(authorDirectoryProvider.notifier).syncWithEpisodes(episodes);
    final authors = ref.watch(authorDirectoryProvider);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _FeedHeader(onProfileTap: () => context.push('/profile')),
        ),
        SliverToBoxAdapter(
          child: _FormatSwitchBar(
            selected: filters.format,
            onSelected: coverageNotifier.setFormat,
          ),
        ),
        if (liveRooms.isNotEmpty)
          SliverToBoxAdapter(
            child: _LiveNowStrip(
              rooms: liveRooms,
              onRoomTap: (room) => context.push('/live/listener', extra: room),
              onFollowToggle: (room) => ref
                  .read(authorDirectoryProvider.notifier)
                  .toggleFollow(room.hostId),
            ),
          ),
        SliverToBoxAdapter(
          child: _FilterPanel(
            filters: filters,
            tags: tags,
            onTabSelected: coverageNotifier.setTab,
            onFormatSelected: coverageNotifier.setFormat,
            onRegionSelected: coverageNotifier.setRegion,
            onTagToggled: (label) {
              coverageNotifier.toggleTag(label);
              tagsNotifier.toggleFollow(label);
            },
            onClearTags: coverageNotifier.clearTags,
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
              return EpisodeCard(
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

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onRecord;

  const _EmptyFeed({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'За вибраними фільтрами нічого немає',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text(
            'Спробуйте інші теги чи регіон, або створіть перший епізод.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton(
            onPressed: onRecord,
            child: const Text('Записати епізод'),
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

class _FormatSwitchBar extends StatelessWidget {
  final ContentFormat selected;
  final ValueChanged<ContentFormat> onSelected;

  const _FormatSwitchBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      child: SegmentedButton<ContentFormat>(
        segments: ContentFormat.values
            .map(
              (format) => ButtonSegment(
                value: format,
                label: Text(format.label),
              ),
            )
            .toList(),
        selected: {selected},
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(AppTheme.bgRaised),
          foregroundColor: MaterialStatePropertyAll(AppTheme.textPrimary),
        ),
        onSelectionChanged: (value) {
          if (value.isNotEmpty) {
            onSelected(value.first);
          }
        },
      ),
    );
  }
}

class _LiveNowStrip extends StatelessWidget {
  final List<LiveRoom> rooms;
  final ValueChanged<LiveRoom> onRoomTap;
  final ValueChanged<LiveRoom> onFollowToggle;

  const _LiveNowStrip({
    required this.rooms,
    required this.onRoomTap,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLg,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: const [
              Text(
                'Прямо зараз',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.podcasts_rounded,
                  color: AppTheme.stateDanger, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spaceMd),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return GestureDetector(
                onTap: () => onRoomTap(room),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFFBE185D)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Text(room.emoji),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.hostName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  room.handle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              room.isFollowedHost
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: () => onFollowToggle(room),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        room.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Text(
                        'LIVE • ${room.listeners} слухачів',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final FeedFilterState filters;
  final List<FeedTag> tags;
  final ValueChanged<FeedTab> onTabSelected;
  final ValueChanged<ContentFormat> onFormatSelected;
  final ValueChanged<RegionFilter> onRegionSelected;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClearTags;

  const _FilterPanel({
    required this.filters,
    required this.tags,
    required this.onTabSelected,
    required this.onFormatSelected,
    required this.onRegionSelected,
    required this.onTagToggled,
    required this.onClearTags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceLg,
      ),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Формати'),
          const SizedBox(height: AppTheme.spaceSm),
          _FormatSelector(
            selected: filters.format,
            onSelected: onFormatSelected,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _SectionLabel('Вкладки стрічки'),
          const SizedBox(height: AppTheme.spaceSm),
          _TabSelector(
            selected: filters.tab,
            onSelected: onTabSelected,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          _SectionLabel('Регіон'),
          const SizedBox(height: AppTheme.spaceSm),
          _RegionSelector(
            selected: filters.tab == FeedTab.trendingNearby
                ? RegionFilter.nearby
                : filters.region,
            locked: filters.tab == FeedTab.trendingNearby,
            onSelected: onRegionSelected,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Теги'),
              if (filters.selectedTags.isNotEmpty)
                TextButton(
                  onPressed: onClearTags,
                  child: const Text('Очистити'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _TagSelector(
            tags: tags,
            selectedTags: filters.selectedTags,
            onTagToggled: onTagToggled,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final ContentFormat selected;
  final ValueChanged<ContentFormat> onSelected;

  const _FormatSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spaceSm,
      children: ContentFormat.values.map((format) {
        final isSelected = selected == format;
        return ChoiceChip(
          label: Text('${format.label} · ${format.description}'),
          selected: isSelected,
          onSelected: (_) => onSelected(format),
          selectedColor: AppTheme.brandPrimary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final FeedTab selected;
  final ValueChanged<FeedTab> onSelected;

  const _TabSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FeedTab.values.map((tab) {
          final isSelected = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spaceSm),
            child: ChoiceChip(
              label: Text(tab.label),
              selected: isSelected,
              onSelected: (_) => onSelected(tab),
              selectedColor: AppTheme.brandAccent.withOpacity(0.2),
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RegionSelector extends StatelessWidget {
  final RegionFilter selected;
  final bool locked;
  final ValueChanged<RegionFilter> onSelected;

  const _RegionSelector({
    required this.selected,
    required this.locked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.surfaceBorder),
        color: AppTheme.surfaceCard,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RegionFilter>(
          value: selected,
          dropdownColor: AppTheme.bgRaised,
          iconEnabledColor: AppTheme.textSecondary,
          onChanged: locked ? null : (value) => onSelected(value ?? selected),
          items: RegionFilter.values.map((region) {
            return DropdownMenuItem(
              value: region,
              child: Text(region.label),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  final List<FeedTag> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  const _TagSelector({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spaceSm,
      runSpacing: AppTheme.spaceSm,
      children: tags.map((tag) {
        final normalized = tag.label.toLowerCase();
        final isSelected = selectedTags.contains(normalized);
        return FilterChip(
          label: Text('${tag.emoji} ${tag.label}'),
          selected: isSelected,
          onSelected: (_) => onTagToggled(tag.label),
          avatar: tag.isFollowed
              ? const Icon(Icons.star, size: 14, color: AppTheme.brandAccent)
              : null,
          selectedColor: AppTheme.brandPrimary.withOpacity(0.15),
          checkmarkColor: AppTheme.textPrimary,
          side: BorderSide(
            color: isSelected ? AppTheme.brandPrimary : AppTheme.surfaceBorder,
          ),
        );
      }).toList(),
    );
  }
}

class _LiveNotificationBanner extends StatelessWidget {
  final LiveNotification notification;

  const _LiveNotificationBanner({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppTheme.brandAccent),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  notification.subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
