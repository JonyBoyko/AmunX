import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/explore.dart';

class ExploreCardTile extends StatelessWidget {
  const ExploreCardTile({
    super.key,
    required this.card,
    this.onTap,
    this.onTagSelected,
  });

  final ExploreCard card;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTagSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceSm,
        ),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(card: card),
            const SizedBox(height: AppTheme.spaceSm),
            if (card.title?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
                child: Text(
                  card.title!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              card.previewSentence.isEmpty
                  ? 'No summary yet'
                  : card.previewSentence,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Wrap(
                spacing: AppTheme.spaceSm,
                runSpacing: AppTheme.spaceSm,
                children: card.tags.map((tag) {
                  return InkWell(
                    onTap: onTagSelected == null
                        ? null
                        : () => onTagSelected!(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgRaised,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLg,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (card.stats != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                children: [
                  _StatChip(icon: Icons.favorite_border, value: card.stats!.likes),
                  const SizedBox(width: AppTheme.spaceSm),
                  _StatChip(icon: Icons.bookmark_border, value: card.stats!.saves),
                  const SizedBox(width: AppTheme.spaceSm),
                  _StatChip(icon: Icons.play_arrow, value: card.stats!.plays),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.card});

  final ExploreCard card;

  @override
  Widget build(BuildContext context) {
    final avatarFallback = card.owner.displayName.isNotEmpty
        ? card.owner.displayName.characters.first
        : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.15),
          backgroundImage: card.owner.avatarUrl?.isNotEmpty == true
              ? NetworkImage(card.owner.avatarUrl!)
              : null,
          child: card.owner.avatarUrl?.isNotEmpty == true
              ? null
              : Text(
                  avatarFallback,
                  style: const TextStyle(color: AppTheme.brandPrimary),
                ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.owner.displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatDuration(card.durationSec)} • ${_formatTimestamp(card.createdAt)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (card.rankScore != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.brandAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'Rank ${(card.rankScore! * 100).toInt()}',
              style: const TextStyle(
                color: AppTheme.brandAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = (seconds / 60).floor();
  final secs = seconds % 60;
  if (minutes <= 0) {
    return '${secs}s';
  }
  if (minutes < 60) {
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }
  final hours = (minutes / 60).floor();
  final restMinutes = minutes % 60;
  return '${hours}h ${restMinutes}m';
}

String _formatTimestamp(DateTime input) {
  final now = DateTime.now();
  final diff = now.difference(input);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}

