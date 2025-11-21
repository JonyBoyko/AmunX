import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../data/models/episode.dart';
import '../models/author_profile.dart';
import '../models/reaction_state.dart';
import 'follow_button.dart';
import 'mini_waveform.dart';
import 'reaction_strip.dart';

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
    final duration = episode.durationSec ?? 0;
    final formattedDuration = duration > 0 ? _formatDuration(duration) : null;
    final topicLabel = episode.keywords?.first ?? 'General';
    final maskLabel = episode.mask;
    final qualityLabel = episode.quality;
    final summary = episode.summary ?? episode.title ?? 'Fresh drop';
    final timestamp = DateFormat('HH:mm').format(episode.createdAt);
    final isLive = episode.isLive;
    final avatarLabel = author?.avatarEmoji ??
        episode.title?.characters.first.toUpperCase() ??
        'A';
    final avatarUrl = author?.avatarUrl;
    final rngValue = Random(episode.id.hashCode).nextDouble();
    final effectiveStatuses =
        statusLabels.isNotEmpty ? statusLabels : _deriveStatuses(episode);
    final effectiveLength = lengthProgress ?? _autoLengthProgress(duration);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.glassStroke),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (effectiveStatuses.isNotEmpty || formattedDuration != null)
              Row(
                children: [
                  if (effectiveStatuses.isNotEmpty)
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      runSpacing: AppTheme.spaceXs,
                      children: effectiveStatuses
                          .map((status) => _StatusBadge(label: status))
                          .toList(),
                    ),
                  const Spacer(),
                  if (formattedDuration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSm,
                        vertical: AppTheme.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.glassSurfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.glassStroke),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDuration,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (effectiveStatuses.isNotEmpty || formattedDuration != null)
              const SizedBox(height: AppTheme.spaceSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarProgress(
                  label: avatarLabel,
                  imageUrl: avatarUrl,
                  progress: rngValue,
                  isLive: author?.isLive ?? isLive,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author?.displayName ??
                                      episode.title ??
                                      'New episode',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  author?.handle ?? '@voice.creator',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (author?.badges.isNotEmpty ?? false)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, right: 4),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: author!.badges
                                          .map(
                                            (badge) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.glassSurfaceLight,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppTheme.radiusSm,
                                                ),
                                                border: Border.all(
                                                  color: AppTheme.glassStroke,
                                                ),
                                              ),
                                              child: Text(
                                                badge,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                if ((author?.isLive ?? isLive) &&
                                    (liveListeners ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceSm,
                                        vertical: AppTheme.spaceXs,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.neonGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm,
                                        ),
                                        boxShadow: [
                                          ...AppTheme.glowPrimary,
                                          ...AppTheme.glowAccent,
                                        ],
                                      ),
                                      child: Text(
                                        'LIVE • ${(liveListeners ?? 0)} listening',
                                        style: const TextStyle(
                                          color: AppTheme.textInverse,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (onFollowToggle != null && author != null)
                            FollowButton(
                              dense: true,
                              isFollowing: author!.isFollowed,
                              onPressed: onFollowToggle!,
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
                          if (formatLabel != null)
                            _Chip(
                              label: formatLabel!,
                              leading: const Icon(
                                Icons.play_circle_outline,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (regionLabel != null)
                            _Chip(
                              label: regionLabel!,
                              leading: const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          _Chip(label: qualityLabel),
                          if (maskLabel.toLowerCase() != 'off')
                            _Chip(label: 'Mask: $maskLabel'),
                          if (formattedDuration != null)
                            _Chip(label: formattedDuration),
                          if (timestamp.isNotEmpty)
                            _Chip(label: timestamp),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                summary,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            _LengthBar(progress: effectiveLength),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                MiniWaveform(
                  progress: rngValue,
                  isActive: isLive,
                ),
                const Spacer(),
                ReactionStrip(
                  snapshot: reactionSnapshot,
                  onTap: onReactionTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  const _Chip({
    required this.label,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.glassStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _AvatarProgress extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final double progress;
  final bool isLive;

  const _AvatarProgress({
    required this.label,
    required this.imageUrl,
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
              strokeWidth: 2.5,
              backgroundColor: AppTheme.glassStroke,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLive ? AppTheme.stateDanger : AppTheme.neonBlue,
              ),
            ),
          ),
          _AvatarLabel(label: label, imageUrl: imageUrl),
        ],
      ),
    );
  }
}

class _AvatarLabel extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const _AvatarLabel({required this.label, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceLight,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppTheme.glassStroke),
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
