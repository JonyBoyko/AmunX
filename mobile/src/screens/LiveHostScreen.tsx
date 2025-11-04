import React, { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';

import { createLiveSession, endLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';

const LiveHostScreen: React.FC = () => {
  const { token } = useSession();

  const [topicId, setTopicId] = useState('');
  const [title, setTitle] = useState('');
  const [recordingKey, setRecordingKey] = useState('');
  const [duration, setDuration] = useState('');
  const [isStarting, setIsStarting] = useState(false);
  const [isEnding, setIsEnding] = useState(false);
  const [response, setResponse] = useState<LiveSessionCreateResponse | null>(null);

  const sessionId = response?.session.id;

  const liveSummary = useMemo(() => {
    if (!response) return null;
    return {
      id: response.session.id,
      room: response.session.room,
      token: response.token,
      url: response.url,
      startedAt: response.session.started_at,
      title: response.session.title ?? ''
    };
  }, [response]);

  const handleStart = useCallback(async () => {
    if (!token) {
      Alert.alert('Sign in required', 'You need to sign in to host live sessions.');
      return;
    }
    if (isStarting) return;
    setIsStarting(true);
    try {
      const payload = {
        topic_id: topicId.trim() || undefined,
        title: title.trim() || undefined
      };
      const res = await createLiveSession(token, payload);
      setResponse(res);
      Alert.alert('Live started', 'Session created. Share the token with co-hosts or use listener flow.');
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to start live session');
    } finally {
      setIsStarting(false);
    }
  }, [isStarting, title, token, topicId]);

  const handleEnd = useCallback(async () => {
    if (!token || !sessionId) {
      return;
    }
    if (isEnding) return;
    setIsEnding(true);
    try {
      const payload: { recording_key?: string; duration_sec?: number } = {};
      if (recordingKey.trim()) {
        payload.recording_key = recordingKey.trim();
      }
      const parsed = parseInt(duration.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) {
        payload.duration_sec = parsed;
      }
      await endLiveSession(token, sessionId, payload);
      Alert.alert('Live ended', 'Session has been marked as ended and will be processed shortly.');
      setResponse(null);
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to end live session');
    } finally {
      setIsEnding(false);
    }
  }, [duration, isEnding, recordingKey, sessionId, token]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Host Live Session</Text>
        <Text style={styles.label}>Topic ID (optional)</Text>
        <TextInput
          value={topicId}
          onChangeText={setTopicId}
          placeholder="topic uuid"
          placeholderTextColor="#64748b"
          style={styles.input}
        />
        <Text style={styles.label}>Title (optional)</Text>
        <TextInput
          value={title}
          onChangeText={setTitle}
          placeholder="Live title"
          placeholderTextColor="#64748b"
          style={styles.input}
        />
        <Button title={isStarting ? 'Starting...' : 'Start Live'} onPress={handleStart} disabled={isStarting} />

        {liveSummary && (
          <View style={styles.section}>
            <Text style={styles.subheading}>Session Info</Text>
            <Text style={styles.info}>ID: {liveSummary.id}</Text>
            <Text style={styles.info}>Room: {liveSummary.room}</Text>
            <Text style={styles.info}>Title: {liveSummary.title}</Text>
            <Text style={styles.info}>Started: {liveSummary.startedAt}</Text>
            <Text style={styles.info}>Token: {liveSummary.token}</Text>
            <Text style={styles.info}>URL: {liveSummary.url}</Text>

            <Text style={styles.label}>Recording Key</Text>
            <TextInput
              value={recordingKey}
              onChangeText={setRecordingKey}
              placeholder="episodes/{id}/processed.opus"
              placeholderTextColor="#64748b"
              style={styles.input}
            />
            <Text style={styles.label}>Duration (seconds)</Text>
            <TextInput
              value={duration}
              onChangeText={setDuration}
              placeholder="e.g. 600"
              placeholderTextColor="#64748b"
              keyboardType="numeric"
              style={styles.input}
            />
            <Button title={isEnding ? 'Ending...' : 'End Live'} onPress={handleEnd} disabled={isEnding} />
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0f172a'
  },
  scroll: {
    padding: 16,
    gap: 16
  },
  heading: {
    color: '#f8fafc',
    fontSize: 22,
    fontWeight: '700'
  },
  label: {
    color: '#cbd5f5',
    fontSize: 14,
    marginTop: 8
  },
  input: {
    backgroundColor: '#1e293b',
    color: '#f1f5f9',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 4
  },
  section: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 16,
    gap: 8
  },
  subheading: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '600'
  },
  info: {
    color: '#cbd5f5'
  }
});

export default LiveHostScreen;
