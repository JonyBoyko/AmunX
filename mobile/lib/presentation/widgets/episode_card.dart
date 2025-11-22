import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              if (effectiveStatuses.isNotEmpty || formattedDuration != null)
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (effectiveStatuses.isNotEmpty)
                      Flexible(
                        child: Wrap(
                          spacing: AppTheme.spaceXs,
                          runSpacing: AppTheme.spaceXs,
                          children: effectiveStatuses
                              .map((status) => _StatusBadge(label: status))
                              .toList(),
                        ),
                      ),
                    if (effectiveStatuses.isNotEmpty &&
                        formattedDuration != null)
                      const SizedBox(width: AppTheme.spaceSm),
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
                mainAxisSize: MainAxisSize.max,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
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
                                  if (author != null &&
                                      (author!.badges.isNotEmpty))
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, right: 4),
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
                                                  color: AppTheme
                                                      .glassSurfaceLight,
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
                                                    color:
                                                        AppTheme.textSecondary,
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
                              _FormatChip(
                                label: formatLabel!,
                                isLive: isLive,
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
                            if (timestamp.isNotEmpty) _Chip(label: timestamp),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (summary.isNotEmpty) ...[
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
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: MiniWaveform(
                      progress: rngValue,
                      isLive: isLive,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Flexible(
                    child: ReactionStrip(
                      snapshot: reactionSnapshot,
                      onTap: onReactionTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _FormatChip extends StatelessWidget {
  final String label;
  final bool isLive;

  const _FormatChip({
    required this.label,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLiveFormat = isLive || label.toLowerCase().contains('live');

    // Згідно з макетом, формати - це звичайні чипи без градієнтів
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.glassStroke,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiveFormat ? Icons.radio : Icons.play_circle_outline,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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

class _LengthBar extends StatelessWidget {
  final double progress;

  const _LengthBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonBlue.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  Color _getBadgeColor(String status) {
    final lower = status.toLowerCase();
    if (lower == 'new' || lower == 'live') {
      return AppTheme.neonBlue;
    } else if (lower == 'ai' ||
        lower.contains('ai') ||
        lower.contains('summary')) {
      return AppTheme.neonBlue; // AI Summary використовує cyan згідно з макетом
    } else if (lower == 'tasks' || lower.contains('task')) {
      return AppTheme.neonPink;
    }
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(label);
    final isNeon = color == AppTheme.neonBlue ||
        color == AppTheme.neonPurple ||
        color == AppTheme.neonPink;

    // Згідно з макетом: bg-[color]/20 border-[color] text-[color]
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            isNeon ? color.withValues(alpha: 0.2) : AppTheme.glassSurfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isNeon ? color : AppTheme.glassStroke,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.toLowerCase().contains('ai') ||
              label.toLowerCase() == 'summary')
            const Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppTheme.neonBlue,
            ),
          if (label.toLowerCase().contains('ai') ||
              label.toLowerCase() == 'summary')
            const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isNeon ? color : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _deriveStatuses(Episode episode) {
  final statuses = <String>[];
  if (episode.isLive) {
    statuses.add('LIVE');
  }
  // Додати логіку для New/AI/Tasks на основі даних епізоду
  // Наприклад, якщо епізод новий (створений < 24 години тому)
  final now = DateTime.now();
  final createdAt = episode.createdAt;
  final hoursSinceCreation = now.difference(createdAt).inHours;
  if (hoursSinceCreation < 24) {
    statuses.add('New');
  }
  // Якщо є AI summary або транскрипт
  if (episode.summary != null && episode.summary!.isNotEmpty) {
    statuses.add('AI');
  }
  return statuses;
}

double _autoLengthProgress(int durationSec) {
  if (durationSec <= 0) return 0.0;
  // Симуляція прогресу прослуховування (можна замінити на реальний прогрес)
  // Для демонстрації використовуємо випадкове значення на основі duration
  final rng = Random(durationSec);
  return rng.nextDouble() * 0.8; // 0-80% прогресу
}

String _formatDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes < 60) {
    return remainingSeconds > 0
        ? '${minutes}m ${remainingSeconds}s'
        : '${minutes}m';
  }
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
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
