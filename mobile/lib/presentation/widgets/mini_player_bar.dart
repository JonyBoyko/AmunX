import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import 'mini_waveform.dart';

class MiniPlayerBar extends StatelessWidget {
  final Episode episode;
  final VoidCallback onPause;
  final VoidCallback? onSkipForward;
  final VoidCallback? onSkipBack;

  const MiniPlayerBar({
    super.key,
    required this.episode,
    required this.onPause,
    this.onSkipForward,
    this.onSkipBack,
  });

  @override
  Widget build(BuildContext context) {
    final label = episode.title ?? 'New episode';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised.withOpacity(0.9),
        border: const Border(
          top: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              (episode.title ?? episode.id).characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const MiniWaveform(
                  barCount: 28,
                  progress: 0.4,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          IconButton(
            onPressed: onSkipBack,
            icon: const Icon(Icons.replay_10, color: AppTheme.textSecondary),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              minimumSize: const Size(44, 44),
              shape: const CircleBorder(),
            ),
            onPressed: onPause,
            child: const Icon(Icons.pause_rounded, color: AppTheme.textInverse),
          ),
          IconButton(
            onPressed: onSkipForward,
            icon: const Icon(Icons.forward_10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

