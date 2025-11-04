import React, { useCallback, useMemo, useState, useEffect } from 'react';
import {
  Alert,
  Button,
  FlatList,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';

import { AudioSession, LiveKitRoom, useLocalParticipant } from '@livekit/react-native';

import { createLiveSession, endLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';

type EventLogEntry = {
  id: string;
  text: string;
  ts: string;
};

const LiveHostScreen: React.FC = () => {
  const { token } = useSession();

  const [topicId, setTopicId] = useState('');
  const [title, setTitle] = useState('');
  const [recordingKey, setRecordingKey] = useState('');
  const [duration, setDuration] = useState('');
  const [isStarting, setIsStarting] = useState(false);
  const [isEnding, setIsEnding] = useState(false);
  const [response, setResponse] = useState<LiveSessionCreateResponse | null>(null);
  const [shouldConnect, setShouldConnect] = useState(false);
  const [roomConnected, setRoomConnected] = useState(false);
  const [events, setEvents] = useState<EventLogEntry[]>([]);

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

  const logEvent = useCallback((text: string) => {
    setEvents((prev) => [
      { id: `evt-${Date.now()}-${Math.random()}`, text, ts: new Date().toISOString() },
      ...prev
    ]);
  }, []);

  useEffect(() => {
    let cancelled = false;
    if (shouldConnect) {
      AudioSession.startAudioSession().catch((err) => {
        if (!cancelled) {
          logEvent(`Audio session error: ${(err as Error).message}`);
        }
      });
    } else {
      AudioSession.stopAudioSession().catch(() => undefined);
    }
    return () => {
      cancelled = true;
      AudioSession.stopAudioSession().catch(() => undefined);
    };
  }, [shouldConnect, logEvent]);

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
      setShouldConnect(true);
      logEvent('Live session created. Connecting as host…');
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to start live session');
      logEvent('Failed to create live session.');
    } finally {
      setIsStarting(false);
    }
  }, [isStarting, logEvent, title, token, topicId]);

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
      logEvent('Live session ended and queued for processing.');
      setResponse(null);
      setShouldConnect(false);
      setRoomConnected(false);
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to end live session');
      logEvent('Failed to end live session.');
    } finally {
      setIsEnding(false);
    }
  }, [duration, isEnding, logEvent, recordingKey, sessionId, token]);

  const handleJoin = useCallback(() => {
    if (!response) {
      Alert.alert('Nothing to join', 'Create a live session first.');
      return;
    }
    logEvent('Connecting to LiveKit room…');
    setShouldConnect(true);
  }, [logEvent, response]);

  const handleLeave = useCallback(() => {
    setShouldConnect(false);
    setRoomConnected(false);
    logEvent('Disconnected from LiveKit room.');
  }, [logEvent]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Host Live Session</Text>
        <Text style={styles.helper}>
          Start a livecast, then connect to the LiveKit room to stream audio. Recording metadata can be supplied when
          ending the session.
        </Text>

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
        <Button title={isStarting ? 'Starting…' : 'Start Live'} onPress={handleStart} disabled={isStarting} />

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

            <View style={styles.buttonRow}>
              <Button title="Join Audio" onPress={handleJoin} disabled={shouldConnect} />
              <Button title="Leave Audio" onPress={handleLeave} disabled={!roomConnected && !shouldConnect} />
            </View>

            <Button
              title={isEnding ? 'Ending…' : 'End Live'}
              onPress={handleEnd}
              color="#ef4444"
              disabled={isEnding}
            />
          </View>
        )}

        {response && shouldConnect && (
          <View style={styles.liveContainer}>
            <LiveKitRoom
              serverUrl={response.url}
              token={response.token}
              connect={true}
              options={{ adaptiveStream: { pixelDensity: 'screen' } }}
              onConnected={() => {
                setRoomConnected(true);
                logEvent('Connected to LiveKit as host.');
              }}
              onDisconnected={() => {
                setRoomConnected(false);
                setShouldConnect(false);
                logEvent('LiveKit connection closed.');
              }}
            >
              <HostControls onEnd={handleEnd} />
            </LiveKitRoom>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.subheading}>Connection Status</Text>
          <Text style={styles.info}>
            {roomConnected ? 'Streaming live audio…' : shouldConnect ? 'Connecting…' : 'Not connected'}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.subheading}>Event Log</Text>
          <FlatList
            data={events}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.eventList}
            renderItem={({ item }) => (
              <View style={styles.eventItem}>
                <Text style={styles.eventText}>{item.text}</Text>
                <Text style={styles.eventTimestamp}>{new Date(item.ts).toLocaleTimeString()}</Text>
              </View>
            )}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const HostControls: React.FC<{ onEnd: () => void }> = ({ onEnd }) => {
  const { localParticipant } = useLocalParticipant();
  const [micEnabled, setMicEnabled] = useState(true);

  const toggleMic = useCallback(async () => {
    try {
      const next = !micEnabled;
      await localParticipant?.setMicrophoneEnabled(next);
      setMicEnabled(next);
    } catch (error: any) {
      Alert.alert('Microphone', error?.message ?? 'Unable to toggle microphone');
    }
  }, [localParticipant, micEnabled]);

  return (
    <View style={styles.liveControls}>
      <Text style={styles.liveStatus}>Host console</Text>
      <Button title={micEnabled ? 'Mute microphone' : 'Unmute microphone'} onPress={toggleMic} />
      <Button title="End session" color="#ef4444" onPress={onEnd} />
    </View>
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
  helper: {
    color: '#cbd5f5'
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
    gap: 12
  },
  subheading: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '600'
  },
  info: {
    color: '#cbd5f5'
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12
  },
  liveContainer: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 16,
    gap: 12
  },
  liveControls: {
    gap: 12
  },
  liveStatus: {
    color: '#38bdf8',
    fontWeight: '600',
    fontSize: 16
  },
  eventList: {
    gap: 8
  },
  eventItem: {
    backgroundColor: '#0b1220',
    borderRadius: 12,
    padding: 12,
    gap: 4
  },
  eventText: {
    color: '#f8fafc'
  },
  eventTimestamp: {
    color: '#64748b',
    fontSize: 12
  }
});

export default LiveHostScreen;
