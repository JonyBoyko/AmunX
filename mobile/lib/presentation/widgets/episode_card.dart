import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import '../models/author_profile.dart';
import '../models/reaction_state.dart';
import 'mini_waveform.dart';
import 'wave_tag_chip.dart';

class EpisodeCard extends StatefulWidget {
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
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;

  void _startPreview() {
    setState(() {
      _isPlaying = true;
      _playbackProgress = 0.0;
    });
    // TODO: фактичний запуск аудіо плеєра
  }

  void _stopPreview() {
    setState(() {
      _isPlaying = false;
      _playbackProgress = 0.0;
    });
    // TODO: зупинка аудіо плеєра
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final author = widget.author;
    final reactionSnapshot = widget.reactionSnapshot;
    final onTap = widget.onTap;
    final onReactionTap = widget.onReactionTap;
    final summary = episode.summary ?? episode.title ?? 'Fresh drop';
    final isLive = episode.isLive;
    final avatarLabel = author?.avatarEmoji ?? episode.title?.characters.first.toUpperCase() ?? 'A';
    final avatarUrl = author?.avatarUrl;
    final rngValue = Random(episode.id.hashCode).nextDouble();
    final waveTags = episode.keywords?.isNotEmpty == true 
      ? episode.keywords! 
      : ['audio', 'voice', 'podcast'];
    final displayName = author?.displayName ?? 'User';
    final handle = author?.handle ?? '@voice';
    final timeAgo = _formatTimeAgo(episode.createdAt);
    final duration = episode.durationSec ?? 0;
    final durationText = duration > 0 ? _formatTime(duration.toDouble()) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassStroke.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Avatar + Name + ~handle + time + ⋯
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Text(avatarLabel, style: const TextStyle(fontSize: 12)) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(displayName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(handle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const Text(' · ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text(timeAgo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 16),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              // Title
              const SizedBox(height: 2),
              Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.2)),
              // Waveform (SoundCloud style)
              const SizedBox(height: 6),
              GestureDetector(
                onLongPressStart: (_) => _startPreview(),
                onLongPressEnd: (_) => _stopPreview(),
                child: Column(
                  children: [
                    MiniWaveform(
                      progress: _isPlaying ? _playbackProgress : rngValue,
                      isLive: isLive,
                      isPlaying: _isPlaying,
                      barCount: 120,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _isPlaying 
                            ? _formatTime((duration * (1 - _playbackProgress)).toDouble())
                            : (durationText ?? ''),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // WaveTags (завжди показуємо)
              WaveTagList(tags: waveTags, maxVisible: 3, variant: WaveTagVariant.cyan, size: WaveTagSize.sm),
              // Interaction bar
              const SizedBox(height: 8),
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

String _formatTime(double seconds) {
  final s = seconds.toInt();
  final mins = s ~/ 60;
  final secs = s % 60;
  return '${mins}:${secs.toString().padLeft(2, '0')}';
}
