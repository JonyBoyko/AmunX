import 'dart:collection';

import 'package:flutter/material.dart';

import '../../data/models/episode.dart';

class ReactionDefinition {
  final String type;
  final String emoji;
  final String label;
  final Color accent;

  const ReactionDefinition({
    required this.type,
    required this.emoji,
    required this.label,
    required this.accent,
  });
}

const reactionDefinitions = [
  ReactionDefinition(
    type: 'like',
    emoji: '👍',
    label: 'Підтримка',
    accent: Color(0xFF6EE7B7),
  ),
  ReactionDefinition(
    type: 'fire',
    emoji: '🔥',
    label: 'На вогні',
    accent: Color(0xFFFF6B6B),
  ),
  ReactionDefinition(
    type: 'idea',
    emoji: '💡',
    label: 'Інсайт',
    accent: Color(0xFFFCD34D),
  ),
  ReactionDefinition(
    type: 'heart',
    emoji: '❤️',
    label: 'Любов',
    accent: Color(0xFFFB7185),
  ),
  ReactionDefinition(
    type: 'clap',
    emoji: '👏',
    label: 'Оплески',
    accent: Color(0xFF7DD3FC),
  ),
];

final _reactionMap = {
  for (final definition in reactionDefinitions) definition.type: definition,
};

ReactionDefinition reactionDefinition(String type) {
  return _reactionMap[type] ?? reactionDefinitions.first;
}

class ReactionSnapshot {
  final UnmodifiableMapView<String, int> totals;
  final UnmodifiableSetView<String> activeTypes;
  final ReactionBadge? badge;
  final bool isUpdating;

  ReactionSnapshot._({
    required Map<String, int> totals,
    required Set<String> activeTypes,
    required this.badge,
    required this.isUpdating,
  })  : totals = UnmodifiableMapView(Map.unmodifiable(totals)),
        activeTypes = UnmodifiableSetView(Set.unmodifiable(activeTypes));

  factory ReactionSnapshot.initial() {
    return ReactionSnapshot._(
      totals: _seedTotals(),
      activeTypes: <String>{},
      badge: null,
      isUpdating: false,
    );
  }

  factory ReactionSnapshot.fromEpisode(Episode episode) {
    return ReactionSnapshot.fromStats(
      stats: episode.reactions ?? const <ReactionStat>[],
      activeTypes: {...episode.selfReactions ?? const <String>[]},
      badge: episode.reactionBadge,
    );
  }

  factory ReactionSnapshot.fromStats({
    Iterable<ReactionStat> stats = const <ReactionStat>[],
    Set<String> activeTypes = const <String>{},
    ReactionBadge? badge,
    bool isUpdating = false,
  }) {
    final totals = _seedTotals();
    for (final stat in stats) {
      totals[stat.type] = stat.count;
    }
    return ReactionSnapshot._(
      totals: totals,
      activeTypes: {...activeTypes},
      badge: badge,
      isUpdating: isUpdating,
    );
  }

  ReactionSnapshot copyWith({
    Map<String, int>? totals,
    Set<String>? activeTypes,
    Object? badge = _snapshotSentinel,
    bool? isUpdating,
  }) {
    return ReactionSnapshot._(
      totals: totals ?? Map.of(this.totals),
      activeTypes: activeTypes ?? Set.of(this.activeTypes),
      badge: identical(badge, _snapshotSentinel)
          ? this.badge
          : badge as ReactionBadge?,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  int countFor(String type) => totals[type] ?? 0;

  bool isActive(String type) => activeTypes.contains(type);
}

Map<String, int> _seedTotals() {
  return {
    for (final definition in reactionDefinitions) definition.type: 0,
  };
}

const _snapshotSentinel = Object();
