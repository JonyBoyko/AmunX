import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import '../providers/feed_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/mini_waveform.dart';

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
                'Не вдалося завантажити епізод',
                style: TextStyle(color: AppTheme.stateDanger),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(episodeDetailProvider(episodeId)),
                child: const Text('Спробувати ще раз'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeDetailBody extends StatefulWidget {
  final Episode episode;
  final bool isPro;

  const _EpisodeDetailBody({
    required this.episode,
    required this.isPro,
  });

  @override
  State<_EpisodeDetailBody> createState() => _EpisodeDetailBodyState();
}

class _EpisodeDetailBodyState extends State<_EpisodeDetailBody>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  int _currentTime = 0;

  @override
  Widget build(BuildContext context) {
    final chapters = [
      {'title': 'Вступ', 'time': 0},
      {'title': 'Головна ідея', 'time': 18},
      {'title': 'Висновки', 'time': 42},
    ];
    final transcript = [
      'Привіт! Сьогодні хочу поділитися думками про нову AI-модель від OpenAI.',
      'Це дійсно цікавий розвиток подій, який може суттєво вплинути на розробку.',
      'Я вважаю, що нам варто підготуватися до цих змін та зрозуміти, як це вплине на нашу роботу.',
      'Давайте подивимось на головні можливості цієї моделі.',
      'Вона може генерувати код, аналізувати великі обсяги даних, і навіть створювати контент.',
      'Але найважливіше - це розуміння контексту та здатність до аналізу.',
      'Це відкриває нові можливості для автоматизації багатьох процесів.',
      'Підсумовуючи, це великий крок вперед для всієї індустрії.',
    ];

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
              const SizedBox(height: AppTheme.spaceLg),
              _buildTabs(chapters, transcript),
            ],
          ),
        ),
        _StickyActions(
          episode: widget.episode,
          onComments: () => context.push(
            '/episode/${widget.episode.id}/comments',
            extra: {'title': widget.episode.title},
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
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
            widget.episode.summary ?? widget.episode.title ?? 'Короткий опис епізоду',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<Map<String, Object>> chapters, List<String> transcript) {
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
                Tab(text: 'Розділи'),
                Tab(text: 'Транскрипт'),
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                            const SizedBox(height: 12),
                            const Text(
                              'Транскрипти доступні у Pro',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Отримайте повний текст епізоду та швидкі розділи.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push('/paywall'),
                              child: const Text('Оновити до Pro'),
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
                      episode.title ?? 'Епізод',
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
  final Episode episode;
  final VoidCallback onComments;

  const _StickyActions({
    required this.episode,
    required this.onComments,
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
            Wrap(
              spacing: 8,
              children: const [
                _ReactionButton(label: '👍'),
                _ReactionButton(label: '🔥'),
                _ReactionButton(label: '💡'),
              ],
            ),
            const Spacer(),
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

class _ReactionButton extends StatelessWidget {
  final String label;

  const _ReactionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceChip,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      alignment: Alignment.center,
      child: Text(label),
    );
  }
}
