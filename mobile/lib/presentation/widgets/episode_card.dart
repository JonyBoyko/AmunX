import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import 'mini_waveform.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final VoidCallback? onTopicTap;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
    this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = episode.durationSec ?? 0;
    final formattedDuration = duration > 0 ? _formatDuration(duration) : null;
    final topicLabel = episode.keywords?.first ?? 'General';
    final maskLabel = episode.mask;
    final qualityLabel = episode.quality;
    final summary = episode.summary ?? episode.title ?? 'Новий епізод';
    final timestamp = DateFormat('HH:mm').format(episode.createdAt);
    final isLive = episode.isLive;
    final avatarInitial = episode.title?.characters.first.toUpperCase() ?? 'A';
    final comments = (episode.mood?['comments'] as int?) ?? (episode.id.hashCode % 12) + 3;
    final rngValue = Random(episode.id.hashCode).nextDouble();

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.surfaceBorder),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarProgress(
                  initial: avatarInitial,
                  progress: rngValue,
                  isLive: isLive,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppTheme.spaceSm,
                        runSpacing: AppTheme.spaceSm,
                        children: [
                          Text(
                            episode.title ?? 'Епізод',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.stateDanger,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXs,
                                ),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textInverse,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppTheme.spaceSm,
                        runSpacing: AppTheme.spaceSm,
                        children: [
                          _Chip(
                            label: topicLabel,
                            onTap: onTopicTap,
                          ),
                          _Chip(label: qualityLabel),
                          if (maskLabel.toLowerCase() != 'off')
                            _Chip(label: 'Mask: ${_capital(maskLabel)}'),
                          if (formattedDuration != null)
                            Text(
                              '• $formattedDuration',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            '• $timestamp',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              summary,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            if (!isLive) ...[
              const SizedBox(height: AppTheme.spaceMd),
              MiniWaveform(progress: rngValue),
            ],
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: AppTheme.spaceSm,
                  children: _buildReactionChips(),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.messenger_outline_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$comments',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceLg),
                    const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactionChips() {
    final reactions = [
      {'emoji': '👍', 'count': (episode.id.hashCode % 30) + 2},
      {'emoji': '🔥', 'count': (episode.id.hashCode % 20) + 1},
      {'emoji': '💡', 'count': (episode.id.hashCode % 15)},
    ];

    return reactions
        .map(
          (reaction) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceChip,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '${reaction['emoji']} ${reaction['count']}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        )
        .toList();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}хв ${remainingSeconds}с';
  }

  String _capital(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceChip,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _AvatarProgress extends StatelessWidget {
  final String initial;
  final double progress;
  final bool isLive;

  const _AvatarProgress({
    required this.initial,
    required this.progress,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: isLive ? null : progress.clamp(0.05, 0.95),
              strokeWidth: 2,
              backgroundColor: AppTheme.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLive ? AppTheme.stateDanger : AppTheme.brandPrimary,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(21),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
