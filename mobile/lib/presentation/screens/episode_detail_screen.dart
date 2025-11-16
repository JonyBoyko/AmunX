import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../data/models/episode.dart';
import '../models/reaction_state.dart';
import '../providers/feed_provider.dart';
import '../providers/session_provider.dart';
import '../providers/reaction_provider.dart';
import '../widgets/mini_waveform.dart';
import '../widgets/reaction_strip.dart';

class EpisodeDetailScreen extends ConsumerWidget {
  final String episodeId;

  const EpisodeDetailScreen({
    super.key,
    required this.episodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeAsync = ref.watch(episodeDetailProvider(episodeId));
    final isPro = ref.watch(sessionProvider).user?.isPro ?? false;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: episodeAsync.when(
        data: (episode) => _EpisodeDetailBody(
          episode: episode,
          isPro: isPro,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'РќРµ РІРґР°Р»РѕСЃСЏ Р·Р°РІР°РЅС‚Р°Р¶РёС‚Рё РµРїС–Р·РѕРґ',
                style: TextStyle(color: AppTheme.stateDanger),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(episodeDetailProvider(episodeId)),
                child: const Text('РЎРїСЂРѕР±СѓРІР°С‚Рё С‰Рµ СЂР°Р·'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeDetailBody extends ConsumerStatefulWidget {
  final Episode episode;
  final bool isPro;

  const _EpisodeDetailBody({
    required this.episode,
    required this.isPro,
  });

  @override
  ConsumerState<_EpisodeDetailBody> createState() => _EpisodeDetailBodyState();
}

class _EpisodeDetailBodyState extends ConsumerState<_EpisodeDetailBody>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  int _currentTime = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reactionProvider.notifier).syncFromEpisodes([widget.episode]);
    });
  }

  @override
  void didUpdateWidget(covariant _EpisodeDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.id != widget.episode.id) {
      ref.read(reactionProvider.notifier).syncFromEpisodes([widget.episode]);
    }
  }

  Future<void> _handleReactionTap(
    BuildContext context,
    String type,
  ) async {
    try {
      await ref.read(reactionProvider.notifier).toggleReaction(
            widget.episode.id,
            type,
          );
    } on StateError {
      _showSnack(
          context, 'РЈРІС–Р№РґС–С‚СЊ, С‰РѕР± СЃС‚Р°РІРёС‚Рё СЂРµР°РєС†С–С—');
    } catch (_) {
      _showSnack(context, 'РќРµ РІРґР°Р»РѕСЃСЏ РѕРЅРѕРІРёС‚Рё СЂРµР°РєС†С–СЋ');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapters = [
      {'title': 'Р’СЃС‚СѓРї', 'time': 0},
      {'title': 'Р“РѕР»РѕРІРЅР° С–РґРµСЏ', 'time': 18},
      {'title': 'Р’РёСЃРЅРѕРІРєРё', 'time': 42},
    ];
    final transcript = [
      'РџСЂРёРІС–С‚! РЎСЊРѕРіРѕРґРЅС– С…РѕС‡Сѓ РїРѕРґС–Р»РёС‚РёСЃСЏ РґСѓРјРєР°РјРё РїСЂРѕ РЅРѕРІСѓ AI-РјРѕРґРµР»СЊ РІС–Рґ OpenAI.',
      'Р¦Рµ РґС–Р№СЃРЅРѕ С†С–РєР°РІРёР№ СЂРѕР·РІРёС‚РѕРє РїРѕРґС–Р№, СЏРєРёР№ РјРѕР¶Рµ СЃСѓС‚С‚С”РІРѕ РІРїР»РёРЅСѓС‚Рё РЅР° СЂРѕР·СЂРѕР±РєСѓ.',
      'РЇ РІРІР°Р¶Р°СЋ, С‰Рѕ РЅР°Рј РІР°СЂС‚Рѕ РїС–РґРіРѕС‚СѓРІР°С‚РёСЃСЏ РґРѕ С†РёС… Р·РјС–РЅ С‚Р° Р·СЂРѕР·СѓРјС–С‚Рё, СЏРє С†Рµ РІРїР»РёРЅРµ РЅР° РЅР°С€Сѓ СЂРѕР±РѕС‚Сѓ.',
      'Р”Р°РІР°Р№С‚Рµ РїРѕРґРёРІРёРјРѕСЃСЊ РЅР° РіРѕР»РѕРІРЅС– РјРѕР¶Р»РёРІРѕСЃС‚С– С†С–С”С— РјРѕРґРµР»С–.',
      'Р’РѕРЅР° РјРѕР¶Рµ РіРµРЅРµСЂСѓРІР°С‚Рё РєРѕРґ, Р°РЅР°Р»С–Р·СѓРІР°С‚Рё РІРµР»РёРєС– РѕР±СЃСЏРіРё РґР°РЅРёС…, С– РЅР°РІС–С‚СЊ СЃС‚РІРѕСЂСЋРІР°С‚Рё РєРѕРЅС‚РµРЅС‚.',
      'РђР»Рµ РЅР°Р№РІР°Р¶Р»РёРІС–С€Рµ - С†Рµ СЂРѕР·СѓРјС–РЅРЅСЏ РєРѕРЅС‚РµРєСЃС‚Сѓ С‚Р° Р·РґР°С‚РЅС–СЃС‚СЊ РґРѕ Р°РЅР°Р»С–Р·Сѓ.',
      'Р¦Рµ РІС–РґРєСЂРёРІР°С” РЅРѕРІС– РјРѕР¶Р»РёРІРѕСЃС‚С– РґР»СЏ Р°РІС‚РѕРјР°С‚РёР·Р°С†С–С— Р±Р°РіР°С‚СЊРѕС… РїСЂРѕС†РµСЃС–РІ.',
      'РџС–РґСЃСѓРјРѕРІСѓСЋС‡Рё, С†Рµ РІРµР»РёРєРёР№ РєСЂРѕРє РІРїРµСЂРµРґ РґР»СЏ РІСЃС–С”С— С–РЅРґСѓСЃС‚СЂС–С—.',
    ];

    final reactionSnapshot =
        ref.watch(reactionSnapshotProvider(widget.episode.id));

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppTheme.spaceLg,
            right: AppTheme.spaceLg,
            bottom: 120,
            top: MediaQuery.of(context).padding.top + AppTheme.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spaceLg),
              _PlayerCard(
                episode: widget.episode,
                isPlaying: _isPlaying,
                currentTime: _currentTime,
                onToggle: () => setState(() => _isPlaying = !_isPlaying),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              _buildTldr(),
              if (AppConfig.reactionsEnabled &&
                  reactionSnapshot.badge != null) ...[
                const SizedBox(height: AppTheme.spaceSm),
                ReactionBadgeChip(badge: reactionSnapshot.badge!),
              ],
              const SizedBox(height: AppTheme.spaceLg),
              _buildTabs(chapters, transcript),
            ],
          ),
        ),
        _StickyActions(
          reactionSnapshot: reactionSnapshot,
          onComments: () => context.push(
            '/episode/${widget.episode.id}/comments',
            extra: {'title': widget.episode.title},
          ),
          onReactionTap: AppConfig.reactionsEnabled
              ? (type) => _handleReactionTap(context, type)
              : null,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTldr() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TL;DR',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.episode.summary ??
                widget.episode.title ??
                'РљРѕСЂРѕС‚РєРёР№ РѕРїРёСЃ РµРїС–Р·РѕРґСѓ',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(
      List<Map<String, Object>> chapters, List<String> transcript) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const TabBar(
              indicatorColor: AppTheme.brandPrimary,
              tabs: [
                Tab(text: 'Р РѕР·РґС–Р»Рё'),
                Tab(text: 'РўСЂР°РЅСЃРєСЂРёРїС‚'),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceLg,
                  ),
                  itemCount: chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return ListTile(
                      tileColor: AppTheme.bgRaised,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      onTap: () => setState(() {
                        _currentTime = chapter['time'] as int;
                      }),
                      title: Text(
                        chapter['title'] as String,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      trailing: Text(
                        '00:${(chapter['time'] as int).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
                widget.isPro
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceLg,
                        ),
                        itemCount: transcript.length,
                        itemBuilder: (context, index) {
                          final text = transcript[index];
                          final isAlt = index.isEven;
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: isAlt
                                  ? AppTheme.bgRaised.withOpacity(0.8)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        margin: const EdgeInsets.only(top: AppTheme.spaceLg),
                        padding: const EdgeInsets.all(AppTheme.spaceXl),
                        decoration: BoxDecoration(
                          color: AppTheme.bgRaised,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXl),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline,
                                color: AppTheme.textSecondary),
                            const SizedBox(height: 12),
                            const Text(
                              'РўСЂР°РЅСЃРєСЂРёРїС‚Рё РґРѕСЃС‚СѓРїРЅС– Сѓ Pro',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'РћС‚СЂРёРјР°Р№С‚Рµ РїРѕРІРЅРёР№ С‚РµРєСЃС‚ РµРїС–Р·РѕРґСѓ С‚Р° С€РІРёРґРєС– СЂРѕР·РґС–Р»Рё.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push('/paywall'),
                              child: const Text('РћРЅРѕРІРёС‚Рё РґРѕ Pro'),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Episode episode;
  final bool isPlaying;
  final int currentTime;
  final VoidCallback onToggle;

  const _PlayerCard({
    required this.episode,
    required this.isPlaying,
    required this.currentTime,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final topicLabel = episode.keywords?.first ?? 'General';
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF402080), Color(0xFFB83290)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (episode.title ?? 'A').characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title ?? 'Р•РїС–Р·РѕРґ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _gradientChip(topicLabel),
                        _gradientChip(episode.quality),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.white,
                minimumSize: const Size(80, 80),
              ),
              onPressed: onToggle,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          MiniWaveform(progress: currentTime / (episode.durationSec ?? 60)),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '00:${currentTime.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatDuration(episode.durationSec ?? 60),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _StickyActions extends StatelessWidget {
  final VoidCallback onComments;
  final ReactionSnapshot reactionSnapshot;
  final ValueChanged<String>? onReactionTap;

  const _StickyActions({
    required this.onComments,
    required this.reactionSnapshot,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppTheme.bgRaised.withOpacity(0.95),
          border: const Border(
            top: BorderSide(color: AppTheme.surfaceBorder),
          ),
        ),
        child: Row(
          children: [
            if (AppConfig.reactionsEnabled) ...[
              Expanded(
                child: ReactionStrip(
                  snapshot: reactionSnapshot,
                  onTap: onReactionTap,
                ),
              ),
              const SizedBox(width: 12),
            ],
            FilledButton.tonal(
              onPressed: onComments,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () {},
              child: const Icon(Icons.share),
            ),
          ],
        ),
      ),
    );
  }
}
