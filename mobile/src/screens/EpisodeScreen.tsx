import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Alert, Button, FlatList, SafeAreaView, StyleSheet, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Audio, InterruptionModeAndroid, InterruptionModeIOS } from 'expo-av';
import type { AVPlaybackStatus } from 'expo-av';

import type { RootStackParamList } from '@navigation/RootNavigator';
import { getEpisodeById, type FeedEpisode } from '@api/feed';
import { listComments, postComment, type Comment } from '@api/comments';
import { submitReport } from '@api/reports';
import { useSession } from '@store/session';

type Props = NativeStackScreenProps<RootStackParamList, 'Episode'>;

const EpisodeScreen: React.FC<Props> = ({ route, navigation }) => {
  const { id } = route.params;
  const { token } = useSession();
  const [episode, setEpisode] = useState<FeedEpisode | null>(null);
  const [loading, setLoading] = useState(true);
  const [comments, setComments] = useState<Comment[]>([]);
  const [commentText, setCommentText] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [reporting, setReporting] = useState(false);
  const [playbackStatus, setPlaybackStatus] = useState<AVPlaybackStatus | null>(null);
  const [isLoadingSound, setIsLoadingSound] = useState(false);

  const soundRef = useRef<Audio.Sound | null>(null);

  const load = async () => {
    try {
      setLoading(true);
      const ep = await getEpisodeById(id);
      setEpisode(ep);
      const res = await listComments(id);
      setComments(res.items);
    } catch (e: any) {
      Alert.alert('Error', e?.message ?? 'Failed to load episode');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [id]);

  useEffect(() => {
    return () => {
      if (soundRef.current) {
        void soundRef.current.unloadAsync();
        soundRef.current = null;
      }
      setPlaybackStatus(null);
    };
  }, [id]);

  useEffect(() => {
    return () => {
      if (soundRef.current) {
        void soundRef.current.unloadAsync();
        soundRef.current = null;
      }
    };
  }, []);

  const onSubmitComment = async () => {
    if (!token) {
      Alert.alert('Sign in required', 'Please sign in to comment.');
      return;
    }
    const text = commentText.trim();
    if (!text) return;
    try {
      setSubmitting(true);
      const res = await postComment(token, id, text);
      setComments((prev) => [res.comment, ...prev]);
      setCommentText('');
      if (res.flagged) {
        Alert.alert('Notice', 'Your comment was flagged for moderation keywords.');
      }
    } catch (e: any) {
      Alert.alert('Error', e?.message ?? 'Failed to post comment');
    } finally {
      setSubmitting(false);
    }
  };

  const promptReport = (objectRef: string) => {
    if (!token) {
      Alert.alert('Sign in required', 'Please sign in to report content.');
      return;
    }
    if (reporting) return;
    const reasons = ['Harassment', 'Spam', 'Sensitive', 'Other'];
    Alert.alert(
      'Report content',
      'Why are you reporting this?',
      [
        ...reasons.map((reason) => ({
          text: reason,
          onPress: () => submitReportWithReason(objectRef, reason)
        })),
        { text: 'Cancel', style: 'cancel' }
      ],
      { cancelable: true }
    );
  };

  const submitReportWithReason = async (objectRef: string, reason: string) => {
    if (!token) return;
    try {
      setReporting(true);
      await submitReport(token, { object_ref: objectRef, reason });
      Alert.alert('Report submitted', 'Thanks - our moderators will review it soon.');
    } catch (e: any) {
      Alert.alert('Error', e?.message ?? 'Failed to submit report');
    } finally {
      setReporting(false);
    }
  };

  const ensureSound = useCallback(async (): Promise<Audio.Sound> => {
    if (!episode?.audio_url) {
      throw new Error('No audio available for this episode.');
    }
    if (soundRef.current) {
      return soundRef.current;
    }
    setIsLoadingSound(true);
    try {
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: false,
        playsInSilentModeIOS: true,
        staysActiveInBackground: false,
        interruptionModeIOS: InterruptionModeIOS.DoNotMix,
        interruptionModeAndroid: InterruptionModeAndroid.DoNotMix,
        shouldDuckAndroid: true
      });
      const { sound } = await Audio.Sound.createAsync(
        { uri: episode.audio_url },
        { shouldPlay: false },
        (status) => setPlaybackStatus(status)
      );
      soundRef.current = sound;
      return sound;
    } finally {
      setIsLoadingSound(false);
    }
  }, [episode?.audio_url]);

  const handleTogglePlayback = useCallback(async () => {
    if (!episode?.audio_url) {
      Alert.alert('Unavailable', 'Processed audio is not ready yet.');
      return;
    }
    try {
      const sound = await ensureSound();
      const status = await sound.getStatusAsync();
      if (status.isLoaded) {
        if (status.isPlaying) {
          await sound.pauseAsync();
        } else {
          if (status.durationMillis && status.positionMillis >= status.durationMillis) {
            await sound.setPositionAsync(0);
          }
          await sound.playAsync();
        }
      } else {
        await sound.playAsync();
      }
    } catch (error: any) {
      Alert.alert('Playback error', error?.message ?? 'Unable to play audio');
    }
  }, [ensureSound, episode?.audio_url]);

  const handleStopPlayback = useCallback(async () => {
    if (!soundRef.current) return;
    try {
      const status = await soundRef.current.getStatusAsync();
      if (status.isLoaded) {
        await soundRef.current.stopAsync();
        await soundRef.current.setPositionAsync(0);
        const refreshed = await soundRef.current.getStatusAsync();
        setPlaybackStatus(refreshed);
      }
    } catch (error: any) {
      Alert.alert('Playback error', error?.message ?? 'Unable to stop audio');
    }
  }, []);

  const playbackState = (() => {
    const status = playbackStatus;
    if (status && status.isLoaded) {
      return {
        isLoaded: true,
        isPlaying: status.isPlaying,
        positionMillis: status.positionMillis ?? 0,
        durationMillis: status.durationMillis ?? 0
      };
    }
    return {
      isLoaded: false,
      isPlaying: false,
      positionMillis: 0,
      durationMillis: 0
    };
  })();

  const playbackLabel = !episode?.audio_url
    ? 'Audio processing in progress'
    : playbackState.durationMillis > 0
    ? `${formatMillis(playbackState.positionMillis)} / ${formatMillis(playbackState.durationMillis)}`
    : playbackState.isLoaded
    ? formatMillis(playbackState.positionMillis)
    : 'Tap play to start listening';

  const playbackButtonLabel = isLoadingSound
    ? 'Loading...'
    : playbackState.isPlaying
    ? 'Pause'
    : playbackState.isLoaded
    ? 'Resume'
    : 'Play';

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}><ActivityIndicator /></View>
      </SafeAreaView>
    );
  }

  if (!episode) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}><Text style={styles.error}>Episode not found</Text></View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Button title="Back" onPress={() => navigation.goBack()} />
        <Text style={styles.headerTitle}>{episode.summary ?? 'Voice note'}</Text>
        <Button
          title={reporting ? '...' : 'Report'}
          onPress={() => promptReport(`episodes/${episode.id}`)}
          disabled={reporting}
          color="#f87171"
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.meta}>Mask: {episode.mask}, Quality: {episode.quality}</Text>
        {episode.keywords && episode.keywords.length > 0 && (
          <Text style={styles.meta}>Keywords: {episode.keywords.join(', ')}</Text>
        )}
        <View style={styles.playbackRow}>
          <Button
            title={playbackButtonLabel}
            onPress={handleTogglePlayback}
            disabled={isLoadingSound || !episode.audio_url}
          />
          <Button title="Stop" onPress={handleStopPlayback} disabled={!playbackState.isLoaded || isLoadingSound} />
        </View>
        <Text style={styles.meta}>{playbackLabel}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Comments</Text>
        <View style={styles.row}>
          <TextInput
            style={styles.input}
            placeholder="Write a comment"
            placeholderTextColor="#64748b"
            value={commentText}
            onChangeText={setCommentText}
          />
          <Button title={submitting ? '...' : 'Send'} onPress={onSubmitComment} disabled={submitting} />
        </View>
        <FlatList
          data={comments}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ gap: 8, paddingTop: 8 }}
          renderItem={({ item }) => (
            <View style={styles.comment}>
              <Text style={styles.commentText}>{item.text}</Text>
              <View style={styles.commentFooter}>
                <Text style={styles.commentMeta}>{new Date(item.created_at).toLocaleString()}</Text>
                <Button
                  title="Report"
                  onPress={() => promptReport(`comments/${item.id}`)}
                  color="#f87171"
                  disabled={reporting}
                />
              </View>
            </View>
          )}
        />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f172a', padding: 16, gap: 12 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 },
  headerTitle: { color: '#f8fafc', fontSize: 18, fontWeight: '700' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  error: { color: '#f87171' },
  card: { backgroundColor: '#1e293b', borderRadius: 16, padding: 16, gap: 8 },
  meta: { color: '#cbd5f5' },
  sectionTitle: { color: '#cbd5f5', fontSize: 14, fontWeight: '600' },
  playbackRow: { flexDirection: 'row', gap: 12, alignItems: 'center' },
  row: { flexDirection: 'row', gap: 8, alignItems: 'center' },
  input: { flex: 1, backgroundColor: '#0f172a', color: '#f8fafc', borderRadius: 8, paddingHorizontal: 12, height: 40 },
  comment: { backgroundColor: '#0b1220', borderRadius: 12, padding: 12 },
  commentText: { color: '#f8fafc' },
  commentFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 6 },
  commentMeta: { color: '#64748b', fontSize: 12 }
});

export default EpisodeScreen;

function formatMillis(value: number): string {
  const totalSeconds = Math.floor(value / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}
