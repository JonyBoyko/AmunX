import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import TrackPlayer, {
  useProgress,
  usePlaybackState,
  State,
} from 'react-native-track-player';
import { useQuery } from '@tanstack/react-query';
import { audioAPI } from '../api/audio';
import { recordFeedEvent } from '../api/events';
import { theme } from '../theme/theme';

export const PlayerScreen: React.FC = () => {
  const route = useRoute<any>();
  const navigation = useNavigation();
  const { audioId, audioUrl } = route.params;

  const [playbackSpeed, setPlaybackSpeed] = useState(1.0);
  const [skipSilence, setSkipSilence] = useState(false);
  const [currentSentence, setCurrentSentence] = useState(0);

  const { position, duration } = useProgress();
  const playbackState = usePlaybackState();

  // Fetch audio details
  const { data: audio } = useQuery({
    queryKey: ['audio', audioId],
    queryFn: () => audioAPI.getAudioItem(audioId),
  });

  // Fetch transcript
  const { data: transcript } = useQuery({
    queryKey: ['transcript', audioId],
    queryFn: () => fetch(`/audio/${audioId}/transcript`).then(r => r.json()),
    enabled: !!audioId,
  });

  useEffect(() => {
    // Setup player
    TrackPlayer.setupPlayer().then(() => {
      TrackPlayer.add({
        id: audioId,
        url: audioUrl,
        title: audio?.title || 'Untitled',
        artist: audio?.owner?.display_name || 'Unknown',
      });
      TrackPlayer.play();

      // Record play event
      recordFeedEvent({
        audio_id: audioId,
        event: 'play',
        meta: { source: 'player' },
      });
    });

    return () => {
      TrackPlayer.reset();
    };
  }, [audioId, audioUrl, audio]);

  // Update current sentence based on position
  useEffect(() => {
    if (transcript?.words) {
      const current = transcript.words.findIndex(
        (word: any) => word.start <= position && word.end >= position
      );
      if (current !== -1) {
        setCurrentSentence(current);
      }
    }
  }, [position, transcript]);

  // Track completion
  useEffect(() => {
    if (duration > 0 && position / duration > 0.95) {
      recordFeedEvent({
        audio_id: audioId,
        event: 'complete',
        meta: { duration, position },
      });
    }
  }, [position, duration, audioId]);

  const togglePlayPause = useCallback(async () => {
    if (playbackState === State.Playing) {
      await TrackPlayer.pause();
    } else {
      await TrackPlayer.play();
    }
  }, [playbackState]);

  const changeSpeed = useCallback(() => {
    const speeds = [1.0, 1.25, 1.5];
    const currentIndex = speeds.indexOf(playbackSpeed);
    const nextSpeed = speeds[(currentIndex + 1) % speeds.length];
    setPlaybackSpeed(nextSpeed);
    TrackPlayer.setRate(nextSpeed);
  }, [playbackSpeed]);

  const seekTo = useCallback(async (seconds: number) => {
    await TrackPlayer.seekTo(seconds);
  }, []);

  const handleShare = useCallback(() => {
    // TODO: Open share modal
    recordFeedEvent({
      audio_id: audioId,
      event: 'share',
      meta: { source: 'player' },
    });
  }, [audioId]);

  const handleSave = useCallback(async () => {
    await audioAPI.saveAudioItem(audioId);
    recordFeedEvent({
      audio_id: audioId,
      event: 'save',
      meta: { source: 'player' },
    });
  }, [audioId]);

  const handleQuote = useCallback(() => {
    navigation.navigate('QuoteCreator', {
      audioId,
      transcript: transcript?.text,
      words: transcript?.words,
    });
  }, [audioId, transcript, navigation]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>←</Text>
        </TouchableOpacity>
        <Text style={styles.title} numberOfLines={1}>
          {audio?.title || 'Playing...'}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      {/* Waveform / Progress */}
      <View style={styles.progressContainer}>
        <View style={styles.progressBar}>
          <View
            style={[
              styles.progressFill,
              { width: `${(position / duration) * 100}%` },
            ]}
          />
        </View>
        <View style={styles.progressLabels}>
          <Text style={styles.progressText}>{formatTime(position)}</Text>
          <Text style={styles.progressText}>{formatTime(duration)}</Text>
        </View>
      </View>

      {/* Controls */}
      <View style={styles.controls}>
        <TouchableOpacity onPress={togglePlayPause} style={styles.playButton}>
          <Text style={styles.playButtonText}>
            {playbackState === State.Playing ? '⏸' : '▶️'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={changeSpeed} style={styles.speedButton}>
          <Text style={styles.speedButtonText}>{playbackSpeed}x</Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={() => setSkipSilence(!skipSilence)}
          style={[styles.toggleButton, skipSilence && styles.toggleButtonActive]}
        >
          <Text style={styles.toggleButtonText}>Skip Silence</Text>
        </TouchableOpacity>
      </View>

      {/* Actions */}
      <View style={styles.actions}>
        <TouchableOpacity onPress={handleSave} style={styles.actionButton}>
          <Text style={styles.actionIcon}>💾</Text>
          <Text style={styles.actionLabel}>Save</Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={handleShare} style={styles.actionButton}>
          <Text style={styles.actionIcon}>↗️</Text>
          <Text style={styles.actionLabel}>Share</Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={handleQuote} style={styles.actionButton}>
          <Text style={styles.actionIcon}>✂️</Text>
          <Text style={styles.actionLabel}>Quote</Text>
        </TouchableOpacity>
      </View>

      {/* Transcript */}
      {transcript && (
        <ScrollView style={styles.transcriptContainer}>
          <Text style={styles.transcriptTitle}>Transcript</Text>
          {transcript.words?.map((word: any, index: number) => (
            <TouchableOpacity
              key={index}
              onPress={() => seekTo(word.start)}
              style={[
                styles.wordChip,
                index === currentSentence && styles.wordChipActive,
              ]}
            >
              <Text
                style={[
                  styles.wordText,
                  index === currentSentence && styles.wordTextActive,
                ]}
              >
                {word.word}{' '}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border.light,
  },
  backButton: {
    fontSize: 28,
    color: theme.colors.text.primary,
  },
  title: {
    flex: 1,
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  progressContainer: {
    padding: theme.spacing.lg,
  },
  progressBar: {
    height: 4,
    backgroundColor: theme.colors.border.light,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.brand.primary,
  },
  progressLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: theme.spacing.sm,
  },
  progressText: {
    fontSize: 12,
    color: theme.colors.text.tertiary,
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  playButton: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  playButtonText: {
    fontSize: 32,
  },
  speedButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
  },
  speedButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  toggleButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  toggleButtonActive: {
    borderColor: theme.colors.brand.primary,
    backgroundColor: theme.colors.brand.primaryLight,
  },
  toggleButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: theme.colors.text.primary,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: theme.spacing.lg,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border.light,
  },
  actionButton: {
    alignItems: 'center',
  },
  actionIcon: {
    fontSize: 28,
    marginBottom: theme.spacing.xs,
  },
  actionLabel: {
    fontSize: 12,
    color: theme.colors.text.secondary,
  },
  transcriptContainer: {
    flex: 1,
    padding: theme.spacing.md,
  },
  transcriptTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  wordChip: {
    display: 'inline-block' as any,
  },
  wordChipActive: {
    backgroundColor: theme.colors.brand.primaryLight,
  },
  wordText: {
    fontSize: 16,
    lineHeight: 28,
    color: theme.colors.text.primary,
  },
  wordTextActive: {
    color: theme.colors.brand.primary,
    fontWeight: '600',
  },
});

