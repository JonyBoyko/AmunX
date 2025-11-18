import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import '../models/reaction_state.dart';

class ReactionStrip extends StatelessWidget {
  final ReactionSnapshot snapshot;
  final ValueChanged<String>? onTap;
  final EdgeInsetsGeometry padding;

  const ReactionStrip({
    super.key,
    required this.snapshot,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final children = reactionDefinitions.map((definition) {
      final count = snapshot.countFor(definition.type);
      final isActive = snapshot.isActive(definition.type);
      return _ReactionPill(
        definition: definition,
        count: count,
        isActive: isActive,
        isUpdating: snapshot.isUpdating,
        onTap: onTap,
      );
    }).toList();

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: AppTheme.spaceSm,
        runSpacing: AppTheme.spaceSm,
        children: children,
      ),
    );
  }
}

class ReactionBadgeChip extends StatelessWidget {
  final ReactionBadge badge;

  const ReactionBadgeChip({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final gradient =
        _badgeGradients[(badge.level - 1).clamp(0, _badgeGradients.length - 1)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        '${badge.emoji} ${badge.label}',
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  final ReactionDefinition definition;
  final int count;
  final bool isActive;
  final bool isUpdating;
  final ValueChanged<String>? onTap;

  const _ReactionPill({
    required this.definition,
    required this.count,
    required this.isActive,
    required this.isUpdating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        isActive ? definition.accent.withValues(alpha: 0.24) : AppTheme.surfaceChip;
    final borderColor = isActive ? definition.accent : AppTheme.surfaceBorder;

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(definition.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: borderColor),
          boxShadow: isUpdating && isActive
              ? [
                  BoxShadow(
                    color: definition.accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(definition.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$count',
                key: ValueKey('${definition.type}-$count'),
                style: TextStyle(
                  color:
                      isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _badgeGradients = [
  [Color(0xFFE0F2F1), Color(0xFFC8E6C9)],
  [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
  [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
];

