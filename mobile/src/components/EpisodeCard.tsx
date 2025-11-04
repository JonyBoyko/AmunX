import React from 'react';
import { View, Text, StyleSheet, Pressable, TouchableOpacity } from 'react-native';
import type { FeedEpisode } from '@api/feed';
import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';

type EpisodeCardProps = {
  episode: FeedEpisode;
  onPress: (id: string) => void;
  onReact?: (id: string, type: string) => void;
};

export const EpisodeCard: React.FC<EpisodeCardProps> = ({ episode, onPress, onReact }) => {
  const title = episode.title || episode.summary || 'Voice note';
  const isAnon = episode.visibility === 'anon';
  const hasAudio = Boolean(episode.audio_url);

  const formatDuration = (seconds?: number) => {
    if (!seconds) return null;
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getVisibilityBadgeColor = () => {
    switch (episode.visibility) {
      case 'public':
        return { bg: '#3b82f633', text: '#93c5fd' };
      case 'anon':
        return { bg: '#a855f733', text: '#d8b4fe' };
      case 'private':
        return { bg: '#6b728033', text: '#cbd5e1' };
      default:
        return { bg: '#64748b33', text: '#cbd5e1' };
    }
  };

  const getMaskBadge = () => {
    switch (episode.mask) {
      case 'basic':
        return { icon: '🎙️', label: 'Basic Mask' };
      case 'studio':
        return { icon: '🎧', label: 'Studio Mask' };
      default:
        return null;
    }
  };

  const visibilityColors = getVisibilityBadgeColor();
  const maskBadge = getMaskBadge();
  const duration = formatDuration(episode.duration_sec);

  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
      onPress={() => onPress(episode.id)}
    >
      {/* Header: Badges */}
      <View style={styles.badgeRow}>
        {episode.is_live && (
          <View style={[styles.badge, { backgroundColor: '#22c55e33' }]}>
            <Text style={[styles.badgeText, { color: '#bbf7d0' }]}>🔴 Live replay</Text>
          </View>
        )}
        <View style={[styles.badge, { backgroundColor: visibilityColors.bg }]}>
          <Text style={[styles.badgeText, { color: visibilityColors.text }]}>
            {isAnon ? '👤 Anon' : '🌐 Public'}
          </Text>
        </View>
        {maskBadge && (
          <View style={[styles.badge, { backgroundColor: '#8b5cf633' }]}>
            <Text style={[styles.badgeText, { color: '#d8b4fe' }]}>
              {maskBadge.icon} {maskBadge.label}
            </Text>
          </View>
        )}
      </View>

      {/* Title/Summary */}
      <Text style={styles.title} numberOfLines={2}>
        {title}
      </Text>

      {/* Metadata */}
      <View style={styles.metaRow}>
        <View style={styles.metaItem}>
          <Text style={styles.metaLabel}>Quality</Text>
          <Text style={styles.metaValue}>{episode.quality}</Text>
        </View>
        {duration && (
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>Duration</Text>
            <Text style={styles.metaValue}>{duration}</Text>
          </View>
        )}
        {episode.published_at && (
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>Published</Text>
            <Text style={styles.metaValue}>
              {new Date(episode.published_at).toLocaleDateString()}
            </Text>
          </View>
        )}
      </View>

      {/* Keywords */}
      {episode.keywords && episode.keywords.length > 0 && (
        <View style={styles.keywordsRow}>
          {episode.keywords.slice(0, 4).map((keyword, idx) => (
            <View key={idx} style={styles.keywordChip}>
              <Text style={styles.keywordText}>#{keyword}</Text>
            </View>
          ))}
          {episode.keywords.length > 4 && (
            <Text style={styles.keywordMore}>+{episode.keywords.length - 4}</Text>
          )}
        </View>
      )}

      {/* Progress bar placeholder (for playback) */}
      {hasAudio && (
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: '0%' }]} />
        </View>
      )}

      {/* Quick reactions */}
      <View style={styles.actionsRow}>
        <TouchableOpacity
          style={styles.reactionBtn}
          onPress={() => onReact?.(episode.id, 'clap')}
        >
          <Text style={styles.reactionEmoji}>👏</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.reactionBtn}
          onPress={() => onReact?.(episode.id, 'fire')}
        >
          <Text style={styles.reactionEmoji}>🔥</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.reactionBtn}
          onPress={() => onReact?.(episode.id, 'heart')}
        >
          <Text style={styles.reactionEmoji}>❤️</Text>
        </TouchableOpacity>
        <View style={styles.commentsPill}>
          <Text style={styles.commentsText}>💬 Comments</Text>
        </View>
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.lg,
    gap: theme.space.md,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(4),
  },
  cardPressed: {
    opacity: 0.8,
    transform: [{ scale: 0.98 }]
  },
  badgeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.space.xs + 2,
  },
  badge: {
    paddingHorizontal: theme.space.sm,
    paddingVertical: theme.space.xs,
    borderRadius: theme.radius.sm,
    alignSelf: 'flex-start',
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  title: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
    lineHeight: 24,
  },
  metaRow: {
    flexDirection: 'row',
    gap: 16,
    flexWrap: 'wrap'
  },
  metaItem: {
    gap: 2
  },
  metaLabel: {
    color: theme.colors.text.secondary,
    fontSize: 11,
    fontWeight: '500',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  metaValue: {
    color: theme.colors.text.primary,
    fontSize: 13,
    fontWeight: '600',
  },
  keywordsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6
  },
  keywordChip: {
    backgroundColor: theme.colors.surface.chip,
    paddingHorizontal: theme.space.sm + 2,
    paddingVertical: theme.space.xs,
    borderRadius: theme.radius.md,
  },
  keywordText: {
    color: theme.colors.text.secondary,
    fontSize: 12,
    fontWeight: '500',
  },
  keywordMore: {
    color: theme.colors.text.secondary,
    fontSize: 12,
    fontWeight: '500',
    paddingHorizontal: theme.space.xs + 2,
    paddingVertical: theme.space.xs,
  },
  progressBar: {
    height: 3,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.xs,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.brand.primary,
    borderRadius: theme.radius.xs,
  },
  actionsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingTop: 4
  },
  reactionBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface.chip,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reactionEmoji: {
    fontSize: 20
  },
  commentsPill: {
    marginLeft: 'auto',
    paddingHorizontal: theme.space.md,
    paddingVertical: theme.space.xs + 2,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.xl,
  },
  commentsText: {
    color: theme.colors.text.primary,
    fontSize: 13,
    fontWeight: '500',
  },
});

