import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
  StyleSheet,
  ViewStyle,
} from 'react-native';
import { theme } from '../theme/theme';

interface AudioCardProps {
  card: {
    id: string;
    kind: 'audio_item' | 'clip';
    owner: {
      id: string;
      display_name: string;
      avatar_url?: string;
    };
    duration_sec: number;
    preview_sentence?: string;
    title?: string;
    quote?: string;
    tags?: string[];
    waveform_peaks?: number[];
    audio_url: string;
    stats?: {
      likes: number;
      plays: number;
    };
  };
  onPress: () => void;
  onVisible?: () => void;
  style?: ViewStyle;
}

export const AudioCard: React.FC<AudioCardProps> = ({
  card,
  onPress,
  onVisible,
  style,
}) => {
  const visibleRef = useRef(false);

  useEffect(() => {
    // Call onVisible once when component mounts (simulates impression)
    if (onVisible && !visibleRef.current) {
      onVisible();
      visibleRef.current = true;
    }
  }, [onVisible]);

  const formatDuration = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      {/* Mini waveform or placeholder */}
      <View style={styles.waveformContainer}>
        {card.waveform_peaks ? (
          <WaveformMini peaks={card.waveform_peaks} />
        ) : (
          <View style={styles.waveformPlaceholder} />
        )}
        <View style={styles.durationBadge}>
          <Text style={styles.durationText}>{formatDuration(card.duration_sec)}</Text>
        </View>
      </View>

      {/* Content */}
      <View style={styles.content}>
        {/* Owner info */}
        <View style={styles.ownerRow}>
          {card.owner.avatar_url ? (
            <Image
              source={{ uri: card.owner.avatar_url }}
              style={styles.avatar}
            />
          ) : (
            <View style={[styles.avatar, styles.avatarPlaceholder]} />
          )}
          <Text style={styles.ownerName} numberOfLines={1}>
            {card.owner.display_name}
          </Text>
        </View>

        {/* Preview text */}
        <Text style={styles.previewText} numberOfLines={3}>
          {card.kind === 'clip' && card.quote
            ? `"${card.quote}"`
            : card.preview_sentence || card.title || 'No preview available'}
        </Text>

        {/* Tags */}
        {card.tags && card.tags.length > 0 && (
          <View style={styles.tagsRow}>
            {card.tags.slice(0, 2).map((tag) => (
              <View key={tag} style={styles.tag}>
                <Text style={styles.tagText}>#{tag}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Stats */}
        {card.stats && (
          <View style={styles.statsRow}>
            <Text style={styles.statsText}>
              ❤️ {card.stats.likes} · ▶️ {card.stats.plays}
            </Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );
};

// Mini waveform component
const WaveformMini: React.FC<{ peaks: number[] }> = ({ peaks }) => {
  // Sample every Nth peak to fit in small space
  const sampledPeaks = peaks.filter((_, i) => i % 5 === 0).slice(0, 20);

  return (
    <View style={styles.waveform}>
      {sampledPeaks.map((peak, i) => (
        <View
          key={i}
          style={[
            styles.waveformBar,
            { height: `${Math.max(peak * 100, 10)}%` },
          ]}
        />
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  waveformContainer: {
    height: 100,
    backgroundColor: theme.colors.brand.primaryLight,
    position: 'relative',
  },
  waveform: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    paddingHorizontal: theme.spacing.sm,
  },
  waveformBar: {
    width: 3,
    backgroundColor: theme.colors.brand.primary,
    borderRadius: 2,
  },
  waveformPlaceholder: {
    flex: 1,
    backgroundColor: theme.colors.brand.primaryLight,
  },
  durationBadge: {
    position: 'absolute',
    bottom: theme.spacing.xs,
    right: theme.spacing.xs,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: theme.spacing.xs,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.sm,
  },
  durationText: {
    color: '#fff',
    fontSize: 11,
    fontWeight: '600',
  },
  content: {
    padding: theme.spacing.sm,
  },
  ownerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  avatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    marginRight: theme.spacing.xs,
  },
  avatarPlaceholder: {
    backgroundColor: theme.colors.border.light,
  },
  ownerName: {
    flex: 1,
    fontSize: 12,
    fontWeight: '600',
    color: theme.colors.text.secondary,
  },
  previewText: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  tagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: theme.spacing.xs,
  },
  tag: {
    backgroundColor: theme.colors.background.tertiary,
    paddingHorizontal: theme.spacing.xs,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.sm,
    marginRight: theme.spacing.xs,
    marginBottom: theme.spacing.xs,
  },
  tagText: {
    fontSize: 11,
    color: theme.colors.brand.primary,
    fontWeight: '500',
  },
  statsRow: {
    flexDirection: 'row',
  },
  statsText: {
    fontSize: 11,
    color: theme.colors.text.tertiary,
  },
});

