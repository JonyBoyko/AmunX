import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  Alert,
  Animated,
} from 'react-native';
import { Audio } from 'expo-av';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { useTranslation } from 'react-i18next';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Badge } from '@components/atoms/Badge';
import { Chip } from '@components/atoms/Chip';
import { UndoToast } from '@components/molecules/UndoToast';
import { useSession } from '@store/session';
import { uploadEpisode, deleteEpisode } from '@api/episodes';

type RecorderScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const MAX_DURATION_MS = 60 * 1000; // 1 minute
const UNDO_SECONDS = 10;

const RecorderScreen: React.FC<RecorderScreenProps> = ({ navigation }) => {
  const { token } = useSession();
  const { t } = useTranslation();
  const [isRecording, setIsRecording] = useState(false);
  const [duration, setDuration] = useState(0);
  const [isPublic, setIsPublic] = useState(true);
  const [mask, setMask] = useState<'none' | 'light' | 'heavy'>('none');
  const [quality, setQuality] = useState<'raw' | 'clean' | 'studio'>('clean');
  const [uploading, setUploading] = useState(false);
  const [showUndo, setShowUndo] = useState(false);
  const [pendingEpisodeId, setPendingEpisodeId] = useState<string | null>(null);

  const recording = useRef<Audio.Recording | null>(null);
  const durationInterval = useRef<NodeJS.Timeout | null>(null);
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    // Request audio permissions
    (async () => {
      const { status } = await Audio.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert(t('recorder.permission.title'), t('recorder.permission.message'));
      }
    })();
  }, [t]);

  useEffect(() => {
    // Pulse animation for recording indicator
    if (isRecording) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.3,
            duration: 800,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 800,
            useNativeDriver: true,
          }),
        ])
      ).start();
    } else {
      pulseAnim.stopAnimation();
      pulseAnim.setValue(1);
    }
  }, [isRecording, pulseAnim]);

  const startRecording = async () => {
    try {
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      const { recording: newRecording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );
      recording.current = newRecording;
      setIsRecording(true);
      setDuration(0);

      // Track duration
      durationInterval.current = setInterval(() => {
        setDuration((prev) => {
          const next = prev + 100;
          if (next >= MAX_DURATION_MS) {
            stopRecording();
            return MAX_DURATION_MS;
          }
          return next;
        });
      }, 100);
    } catch (err: any) {
      Alert.alert(t('common.error'), t('recorder.uploadError') + ': ' + err?.message);
    }
  };

  const stopRecording = async () => {
    if (!recording.current) return;

    try {
      setIsRecording(false);
      if (durationInterval.current) {
        clearInterval(durationInterval.current);
      }

      await recording.current.stopAndUnloadAsync();
      const uri = recording.current.getURI();
      recording.current = null;

      if (uri) {
        handleUpload(uri);
      }
    } catch (err: any) {
      Alert.alert(t('common.error'), t('recorder.uploadError') + ': ' + err?.message);
    }
  };

  const handleUpload = async (uri: string) => {
    if (!token) {
      Alert.alert(t('errors.unauthorized'), t('errors.unauthorized'));
      return;
    }

    setUploading(true);

    try {
      const formData = new FormData();
      formData.append('audio', {
        uri,
        type: 'audio/m4a',
        name: `recording_${Date.now()}.m4a`,
      } as any);
      formData.append('title', 'Voice note');
      formData.append('is_public', isPublic ? 'true' : 'false');
      formData.append('mask', mask);
      formData.append('quality', quality);

      const episode = await uploadEpisode(token, formData);
      
      setPendingEpisodeId(episode.id);
      setShowUndo(true);
      setDuration(0);
    } catch (err: any) {
      Alert.alert(t('recorder.uploadError'), err?.message ?? t('common.retry'));
    } finally {
      setUploading(false);
    }
  };

  const handleUndo = async () => {
    if (!pendingEpisodeId || !token) return;

    try {
      await deleteEpisode(token, pendingEpisodeId);
      setPendingEpisodeId(null);
      setShowUndo(false);
      Alert.alert(t('recorder.cancelled.title'), t('recorder.cancelled.message'));
    } catch (err: any) {
      Alert.alert(t('common.error'), t('common.error') + ': ' + err?.message);
    }
  };

  const handleUndoComplete = () => {
    setShowUndo(false);
    setPendingEpisodeId(null);
    Alert.alert(t('recorder.published.title'), t('recorder.published.message'));
    navigation.navigate('Feed');
  };

  const formatDuration = (ms: number) => {
    const seconds = Math.floor(ms / 1000);
    return `${seconds}s / 60s`;
  };

  const progressPercent = (duration / MAX_DURATION_MS) * 100;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Text style={styles.headerTitle}>{t('recorder.title')}</Text>
        <View style={{ width: 40 }} />
      </View>

      {/* Main Content */}
      <View style={styles.content}>
        {/* Status Badges */}
        <View style={styles.badgeRow}>
          <Badge variant={isPublic ? 'public' : 'anon'} />
          {mask !== 'none' && <Badge variant="mask" label={mask.toUpperCase()} />}
          <Badge variant={quality as any} />
        </View>

        {/* Recording Button */}
        <View style={styles.recordSection}>
          <Pressable
            onPress={isRecording ? stopRecording : startRecording}
            disabled={uploading}
            style={styles.recordButtonContainer}
          >
            <Animated.View
              style={[
                styles.recordButton,
                isRecording && styles.recordButtonActive,
                { transform: [{ scale: pulseAnim }] },
              ]}
            >
              <Ionicons
                name={isRecording ? 'stop' : 'mic'}
                size={48}
                color={theme.colors.text.inverse}
              />
            </Animated.View>
          </Pressable>

          {/* Duration */}
          <Text style={styles.durationText}>{formatDuration(duration)}</Text>

          {/* Progress Bar */}
          {isRecording && (
            <View style={styles.progressBarContainer}>
              <View style={[styles.progressBar, { width: `${progressPercent}%` }]} />
            </View>
          )}
        </View>

        {/* Settings */}
        <View style={styles.settings}>
          {/* Privacy Toggle */}
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>{t('recorder.privacy')}</Text>
            <View style={styles.chipGroup}>
              <Chip
                label={t('recorder.public')}
                selected={isPublic}
                onPress={() => setIsPublic(true)}
              />
              <Chip
                label={t('recorder.anonymous')}
                selected={!isPublic}
                onPress={() => setIsPublic(false)}
              />
            </View>
          </View>

          {/* Mask */}
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>{t('recorder.mask')}</Text>
            <View style={styles.chipGroup}>
              <Chip label={t('recorder.maskNone')} selected={mask === 'none'} onPress={() => setMask('none')} />
              <Chip label={t('recorder.maskLight')} selected={mask === 'light'} onPress={() => setMask('light')} />
              <Chip label={t('recorder.maskHeavy')} selected={mask === 'heavy'} onPress={() => setMask('heavy')} />
            </View>
          </View>

          {/* Quality */}
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>{t('recorder.quality')}</Text>
            <View style={styles.chipGroup}>
              <Chip label={t('recorder.qualityRaw')} selected={quality === 'raw'} onPress={() => setQuality('raw')} />
              <Chip label={t('recorder.qualityClean')} selected={quality === 'clean'} onPress={() => setQuality('clean')} />
              <Chip label={t('recorder.qualityStudio')} selected={quality === 'studio'} onPress={() => setQuality('studio')} />
            </View>
          </View>
        </View>

        {/* Instructions */}
        <Text style={styles.instructions}>
          {isRecording
            ? t('recorder.instructions.recording')
            : t('recorder.instructions.idle')}
        </Text>
      </View>

      {/* Undo Toast */}
      {showUndo && (
        <UndoToast
          seconds={UNDO_SECONDS}
          onUndo={handleUndo}
          onComplete={handleUndoComplete}
        />
      )}

      {/* Uploading Overlay */}
      {uploading && (
        <View style={styles.uploadingOverlay}>
          <View style={styles.uploadingCard}>
            <Text style={styles.uploadingText}>{t('recorder.uploading')}</Text>
          </View>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
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
  headerTitle: {
    color: theme.colors.text.primary,
    fontSize: theme.type.h2.size,
    fontWeight: theme.type.h2.weight,
  },
  content: {
    flex: 1,
    paddingHorizontal: theme.space.lg,
    paddingTop: theme.space.xxl,
    gap: theme.space.xxl,
  },
  badgeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.space.sm,
    justifyContent: 'center',
  },
  recordSection: {
    alignItems: 'center',
    gap: theme.space.lg,
  },
  recordButtonContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  recordButton: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(8),
  },
  recordButtonActive: {
    backgroundColor: theme.colors.state.danger,
  },
  durationText: {
    color: theme.colors.text.primary,
    fontSize: 20,
    fontWeight: '600',
  },
  progressBarContainer: {
    width: '80%',
    height: 6,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.xs,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: theme.colors.brand.primary,
    borderRadius: theme.radius.xs,
  },
  settings: {
    gap: theme.space.xl,
  },
  settingRow: {
    gap: theme.space.md,
  },
  settingLabel: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  chipGroup: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.space.sm,
  },
  instructions: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    textAlign: 'center',
    lineHeight: theme.type.caption.lineHeight,
  },
  uploadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 999,
  },
  uploadingCard: {
    backgroundColor: theme.colors.surface.raised,
    paddingHorizontal: theme.space.xxl,
    paddingVertical: theme.space.xl,
    borderRadius: theme.radius.lg,
    ...applyShadow(12),
  },
  uploadingText: {
    color: theme.colors.text.primary,
    fontSize: theme.type.body.size,
    fontWeight: '600',
  },
});

export default RecorderScreen;
