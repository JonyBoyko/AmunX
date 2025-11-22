import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import '../models/author_profile.dart';
import '../models/reaction_state.dart';
import 'mini_waveform.dart';
import 'wave_tag_chip.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final VoidCallback? onTopicTap;
  final String? regionLabel;
  final String? formatLabel;
  final AuthorProfile? author;
  final VoidCallback? onFollowToggle;
  final int? liveListeners;
  final ReactionSnapshot reactionSnapshot;
  final ValueChanged<String>? onReactionTap;
  final List<String> statusLabels;
  final double? lengthProgress;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
    this.onTopicTap,
    this.regionLabel,
    this.formatLabel,
    this.author,
    this.onFollowToggle,
    this.liveListeners,
    required this.reactionSnapshot,
    this.onReactionTap,
    this.statusLabels = const [],
    this.lengthProgress,
  });

  @override
  Widget build(BuildContext context) {
    final summary = episode.summary ?? episode.title ?? 'Fresh drop';
    final isLive = episode.isLive;
    final avatarLabel = author?.avatarEmoji ?? episode.title?.characters.first.toUpperCase() ?? 'A';
    final avatarUrl = author?.avatarUrl;
    final rngValue = Random(episode.id.hashCode).nextDouble();
    final waveTags = episode.keywords?.isNotEmpty == true 
      ? episode.keywords! 
      : ['audio', 'voice', 'podcast']; // Мок-теги для демо
    final displayName = author?.displayName ?? 'User';
    final handle = author?.handle ?? '@voice';
    final timeAgo = _formatTimeAgo(episode.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassStroke),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Avatar + Name + ~handle + time + ⋯
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Text(avatarLabel, style: const TextStyle(fontSize: 14)) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(displayName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(handle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                        Text(timeAgo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              // Title
              const SizedBox(height: 8),
              Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.4)),
              // Waveform
              const SizedBox(height: 12),
              GestureDetector(
                onLongPressStart: (_) {},
                onLongPressEnd: (_) {},
                child: MiniWaveform(progress: rngValue, isLive: isLive),
              ),
              // WaveTags (завжди показуємо)
              const SizedBox(height: 8),
              WaveTagList(tags: waveTags, maxVisible: 3, variant: WaveTagVariant.cyan, size: WaveTagSize.sm),
              // Interaction bar
              const SizedBox(height: 12),
              Row(
                children: [
                  _InteractionButton(icon: Icons.mode_comment_outlined, count: 0, onTap: () {}),
                  const SizedBox(width: 24),
                  _InteractionButton(icon: Icons.repeat, count: 0, onTap: () {}),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => onReactionTap?.call('like'),
                    onLongPress: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reactionSnapshot.isActive('like') ? Icons.favorite : Icons.favorite_border,
                          color: reactionSnapshot.isActive('like') ? AppTheme.neonPink : AppTheme.textSecondary,
                          size: 18,
                        ),
                        if (reactionSnapshot.countFor('like') > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${reactionSnapshot.countFor('like')}',
                            style: TextStyle(
                              color: reactionSnapshot.isActive('like') ? AppTheme.neonPink : AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  _InteractionButton(icon: Icons.bookmark_border, count: null, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  const _InteractionButton({required this.icon, this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text('$count', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inDays > 0) return '${diff.inDays}д';
  if (diff.inHours > 0) return '${diff.inHours}г';
  if (diff.inMinutes > 0) return '${diff.inMinutes}хв';
  return 'щойно';
}
