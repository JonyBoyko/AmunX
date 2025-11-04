import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  ScrollView,
  ActivityIndicator,
  Alert,
  Share,
} from 'react-native';
import { Audio } from 'expo-av';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RouteProp } from '@react-navigation/native';
import { useTranslation } from 'react-i18next';
import Slider from '@react-native-community/slider';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Badge } from '@components/atoms/Badge';
import { Button } from '@components/atoms/Button';
import { Chip } from '@components/atoms/Chip';
import { useSession } from '@store/session';
import { getEpisodeById } from '@api/feed';
import { reactToEpisode, getSelfReactions } from '@api/episodes';
import type { FeedEpisode } from '@api/feed';
import { formatSeconds } from '@utils/formatters';

type EpisodeDetailScreenProps = {
  navigation: NativeStackNavigationProp<any>;
  route: RouteProp<{ params: { id: string } }, 'params'>;
};

const REACTIONS = [
  { type: 'like', emoji: '👍' },
  { type: 'love', emoji: '❤️' },
  { type: 'laugh', emoji: '😂' },
  { type: 'wow', emoji: '😮' },
  { type: 'think', emoji: '🤔' },
];

const EpisodeDetailScreen: React.FC<EpisodeDetailScreenProps> = ({ navigation, route }) => {
  const { id } = route.params;
  const { token } = useSession();
  const { t } = useTranslation();

  const [episode, setEpisode] = useState<FeedEpisode | null>(null);
  const [loading, setLoading] = useState(true);
  const [isPlaying, setIsPlaying] = useState(false);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  const [playbackSpeed, setPlaybackSpeed] = useState(1.0);
  const [selfReactions, setSelfReactions] = useState<string[]>([]);

  const soundRef = useRef<Audio.Sound | null>(null);

  useEffect(() => {
    loadEpisode();
  }, [id]);

  useEffect(() => {
    if (episode?.audio_url) {
      loadAudio();
    }
    return () => {
      if (soundRef.current) {
        soundRef.current.unloadAsync();
      }
    };
  }, [episode?.audio_url]);

  const loadEpisode = async () => {
    try {
      setLoading(true);
      const data = await getEpisodeById(id);
      setEpisode(data);

      if (token) {
        const reactions = await getSelfReactions(token, id);
        setSelfReactions(reactions.self);
      }
    } catch (err: any) {
      Alert.alert(t('common.error'), err?.message || t('errors.notFound'));
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  const loadAudio = async () => {
    if (!episode?.audio_url) return;

    try {
      const { sound } = await Audio.Sound.createAsync(
        { uri: episode.audio_url },
        { shouldPlay: false, rate: playbackSpeed },
        (status) => {
          if (status.isLoaded) {
            setPosition(status.positionMillis);
            setDuration(status.durationMillis ?? 0);
            setIsPlaying(status.isPlaying);
            if (status.didJustFinish) {
              setIsPlaying(false);
              setPosition(0);
            }
          }
        }
      );
      soundRef.current = sound;
    } catch (err: any) {
      Alert.alert(t('common.error'), 'Failed to load audio');
    }
  };

  const togglePlayPause = async () => {
    if (!soundRef.current) return;

    try {
      if (isPlaying) {
        await soundRef.current.pauseAsync();
      } else {
        await soundRef.current.playAsync();
      }
    } catch (err) {
      console.error('Playback error:', err);
    }
  };

  const handleSeek = async (value: number) => {
    if (!soundRef.current) return;

    try {
      await soundRef.current.setPositionAsync(value);
    } catch (err) {
      console.error('Seek error:', err);
    }
  };

  const handleSpeedChange = async () => {
    const speeds = [1.0, 1.25, 1.5, 2.0];
    const currentIndex = speeds.indexOf(playbackSpeed);
    const nextSpeed = speeds[(currentIndex + 1) % speeds.length];

    setPlaybackSpeed(nextSpeed);

    if (soundRef.current) {
      try {
        await soundRef.current.setRateAsync(nextSpeed, true);
      } catch (err) {
        console.error('Speed change error:', err);
      }
    }
  };

  const handleReaction = async (type: string) => {
    if (!token) {
      Alert.alert(t('errors.unauthorized'), t('errors.unauthorized'));
      return;
    }

    try {
      const isActive = selfReactions.includes(type);
      const result = await reactToEpisode(token, id, type, isActive);
      setSelfReactions(result.self);
    } catch (err: any) {
      Alert.alert(t('common.error'), err?.message || 'Failed to react');
    }
  };

  const handleShare = async () => {
    try {
      const url = `https://amunx.app/episode/${id}`;
      await Share.share({
        message: `${episode?.title || 'Voice note'} on AmunX\n${url}`,
        url,
      });
    } catch (err) {
      console.error('Share error:', err);
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!episode) {
    return null;
  }

  const title = episode.summary || episode.title || 'Voice note';
  const publishedDate = episode.published_at
    ? new Date(episode.published_at).toLocaleDateString()
    : t('episode.pending');

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Pressable onPress={handleShare} style={styles.shareButton}>
          <Ionicons name="share-outline" size={24} color={theme.colors.text.primary} />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Badges */}
        <View style={styles.badgeRow}>
          {episode.is_live && <Badge variant="live" />}
          {episode.mask !== 'none' && <Badge variant="mask" label={episode.mask?.toUpperCase()} />}
          <Badge variant={episode.quality as any} />
        </View>

        {/* Title */}
        <Text style={styles.title}>{title}</Text>

        {/* Metadata */}
        <View style={styles.metaRow}>
          <Text style={styles.metaText}>
            {publishedDate} • {formatSeconds(episode.duration_sec || 0)}
          </Text>
        </View>

        {/* Keywords */}
        {episode.keywords && episode.keywords.length > 0 && (
          <View style={styles.keywordsRow}>
            {episode.keywords.slice(0, 5).map((keyword, idx) => (
              <Chip key={idx} label={keyword} />
            ))}
          </View>
        )}

        {/* Audio Player */}
        <View style={styles.playerCard}>
          {/* Waveform Placeholder */}
          <View style={styles.waveform}>
            {[...Array(30)].map((_, i) => (
              <View
                key={i}
                style={[
                  styles.waveformBar,
                  {
                    height: Math.random() * 40 + 20,
                    opacity: i < (position / duration) * 30 ? 1 : 0.3,
                  },
                ]}
              />
            ))}
          </View>

          {/* Progress Slider */}
          <Slider
            style={styles.slider}
            minimumValue={0}
            maximumValue={duration}
            value={position}
            onSlidingComplete={handleSeek}
            minimumTrackTintColor={theme.colors.brand.primary}
            maximumTrackTintColor={theme.colors.surface.chip}
            thumbTintColor={theme.colors.brand.primary}
          />

          {/* Time */}
          <View style={styles.timeRow}>
            <Text style={styles.timeText}>{formatSeconds(Math.floor(position / 1000))}</Text>
            <Text style={styles.timeText}>{formatSeconds(Math.floor(duration / 1000))}</Text>
          </View>

          {/* Controls */}
          <View style={styles.controls}>
            <Pressable onPress={() => handleSeek(Math.max(0, position - 15000))} style={styles.controlButton}>
              <Text style={styles.controlButtonText}>-15s</Text>
            </Pressable>

            <Pressable onPress={togglePlayPause} style={styles.playButton}>
              <Ionicons
                name={isPlaying ? 'pause' : 'play'}
                size={32}
                color={theme.colors.text.inverse}
              />
            </Pressable>

            <Pressable onPress={() => handleSeek(Math.min(duration, position + 15000))} style={styles.controlButton}>
              <Text style={styles.controlButtonText}>+15s</Text>
            </Pressable>
          </View>

          {/* Speed Control */}
          <Pressable onPress={handleSpeedChange} style={styles.speedButton}>
            <Text style={styles.speedButtonText}>{playbackSpeed}x</Text>
          </Pressable>
        </View>

        {/* Reactions */}
        <View style={styles.reactionsCard}>
          <Text style={styles.reactionsTitle}>{t('episode.reactions', { defaultValue: 'Reactions' })}</Text>
          <View style={styles.reactionsRow}>
            {REACTIONS.map((reaction) => {
              const isActive = selfReactions.includes(reaction.type);
              return (
                <Pressable
                  key={reaction.type}
                  onPress={() => handleReaction(reaction.type)}
                  style={[
                    styles.reactionButton,
                    isActive && styles.reactionButtonActive,
                  ]}
                >
                  <Text style={styles.reactionEmoji}>{reaction.emoji}</Text>
                </Pressable>
              );
            })}
          </View>
        </View>

        {/* Comments Section */}
        <View style={styles.commentsCard}>
          <Text style={styles.sectionTitle}>{t('episode.comments', { defaultValue: 'Comments' })}</Text>
          <Button
            title={t('comments.viewAll', { defaultValue: 'View all comments' })}
            kind="tonal"
            onPress={() =>
              navigation.navigate('Comments', { episodeId: id, episodeTitle: title })
            }
            icon={<Ionicons name="chatbubbles-outline" size={18} color={theme.colors.text.primary} />}
          />
        </View>

        {/* Action Buttons */}
        <View style={styles.actionsRow}>
          <Button
            title={t('common.close')}
            kind="secondary"
            onPress={() => navigation.goBack()}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.space.md,
  },
  loadingText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.surface.border,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shareButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    padding: theme.space.lg,
    gap: theme.space.xl,
    paddingBottom: theme.space.xxl * 2,
  },
  badgeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.space.xs + 2,
  },
  title: {
    color: theme.colors.text.primary,
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 36,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.space.sm,
  },
  metaText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    fontWeight: '500',
  },
  keywordsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.space.sm,
  },
  playerCard: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.xl,
    gap: theme.space.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(4),
  },
  waveform: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    height: 60,
    gap: 2,
  },
  waveformBar: {
    flex: 1,
    backgroundColor: theme.colors.brand.primary,
    borderRadius: 2,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  timeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  timeText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    fontWeight: '500',
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.space.xl,
  },
  playButton: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(4),
  },
  controlButton: {
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.md,
  },
  controlButtonText: {
    color: theme.colors.text.primary,
    fontSize: 14,
    fontWeight: '600',
  },
  speedButton: {
    alignSelf: 'center',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.sm,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.xl,
  },
  speedButtonText: {
    color: theme.colors.text.primary,
    fontSize: 14,
    fontWeight: '600',
  },
  reactionsCard: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.lg,
    gap: theme.space.md,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
  },
  reactionsTitle: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  reactionsRow: {
    flexDirection: 'row',
    gap: theme.space.md,
  },
  reactionButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: theme.colors.surface.chip,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reactionButtonActive: {
    backgroundColor: theme.colors.brand.primary + '33',
    borderWidth: 2,
    borderColor: theme.colors.brand.primary,
  },
  reactionEmoji: {
    fontSize: 24,
  },
  commentsCard: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.lg,
    gap: theme.space.md,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
  },
  sectionTitle: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  comingSoon: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
    paddingVertical: theme.space.xl,
  },
  actionsRow: {
    gap: theme.space.md,
  },
});

export default EpisodeDetailScreen;

