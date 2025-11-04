import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Pressable, ActivityIndicator, Animated } from 'react-native';
import { Audio } from 'expo-av';
import type { FeedEpisode } from '@api/feed';
import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';

type MiniPlayerProps = {
  episode: FeedEpisode | null;
  onExpand: (episodeId: string) => void;
};

export const MiniPlayer: React.FC<MiniPlayerProps> = ({ episode, onExpand }) => {
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  const slideAnim = useRef(new Animated.Value(-100)).current;

  // Show/hide animation
  useEffect(() => {
    if (episode) {
      Animated.spring(slideAnim, {
        toValue: 0,
        useNativeDriver: true,
        tension: 65,
        friction: 11,
      }).start();
    } else {
      Animated.spring(slideAnim, {
        toValue: -100,
        useNativeDriver: true,
      }).start();
    }
  }, [episode, slideAnim]);

  // Load and play audio when episode changes
  useEffect(() => {
    if (!episode?.audio_url) return;

    const loadSound = async () => {
      try {
        // Unload previous sound
        if (sound) {
          await sound.unloadAsync();
        }

        setIsLoading(true);
        const { sound: newSound } = await Audio.Sound.createAsync(
          { uri: episode.audio_url! },
          { shouldPlay: false },
          onPlaybackStatusUpdate
        );
        setSound(newSound);
        setIsLoading(false);
      } catch (error) {
        console.error('Error loading sound:', error);
        setIsLoading(false);
      }
    };

    loadSound();

    return () => {
      if (sound) {
        sound.unloadAsync();
      }
    };
  }, [episode?.id]);

  const onPlaybackStatusUpdate = (status: any) => {
    if (status.isLoaded) {
      setPosition(status.positionMillis);
      setDuration(status.durationMillis || 0);
      setIsPlaying(status.isPlaying);
    }
  };

  const togglePlayPause = async () => {
    if (!sound) return;

    try {
      if (isPlaying) {
        await sound.pauseAsync();
      } else {
        await sound.playAsync();
      }
    } catch (error) {
      console.error('Error toggling playback:', error);
    }
  };

  if (!episode) return null;

  const title = episode.title || episode.summary || 'Voice note';
  const progress = duration > 0 ? (position / duration) * 100 : 0;

  const formatTime = (millis: number) => {
    const totalSeconds = Math.floor(millis / 1000);
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <Animated.View
      style={[
        styles.container,
        {
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <Pressable style={styles.touchable} onPress={() => onExpand(episode.id)}>
        {/* Progress bar */}
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${progress}%` }]} />
        </View>

        {/* Player controls */}
        <View style={styles.content}>
          <View style={styles.info}>
            <Text style={styles.title} numberOfLines={1}>
              {title}
            </Text>
            <Text style={styles.time}>
              {formatTime(position)} / {formatTime(duration)}
            </Text>
          </View>

          <Pressable style={styles.playButton} onPress={togglePlayPause}>
            {isLoading ? (
              <ActivityIndicator size="small" color="#38bdf8" />
            ) : (
              <Text style={styles.playIcon}>{isPlaying ? '⏸' : '▶'}</Text>
            )}
          </Pressable>
        </View>
      </Pressable>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: theme.colors.surface.raised,
    borderTopLeftRadius: theme.radius.lg,
    borderTopRightRadius: theme.radius.lg,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderRightWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(8),
  },
  touchable: {
    width: '100%',
  },
  progressBar: {
    height: 3,
    backgroundColor: theme.colors.surface.chip,
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.brand.primary,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    gap: theme.space.md,
  },
  info: {
    flex: 1,
    gap: 4,
  },
  title: {
    color: theme.colors.text.primary,
    fontSize: 15,
    fontWeight: '600',
  },
  time: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    fontWeight: '500',
  },
  playButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(2),
  },
  playIcon: {
    fontSize: 18,
    color: theme.colors.text.inverse,
  },
});

