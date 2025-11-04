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

import { AudioSession, LiveKitRoom } from '@livekit/react-native';

import { getLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';

type LogEntry = {
  id: string;
  text: string;
  ts: string;
};

const LiveListenerScreen: React.FC = () => {
  const { token } = useSession();

  const [sessionInput, setSessionInput] = useState('');
  const [role, setRole] = useState<'listener' | 'host'>('listener');
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<LiveSessionCreateResponse | null>(null);
  const [shouldConnect, setShouldConnect] = useState(false);
  const [roomConnected, setRoomConnected] = useState(false);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [messageDraft, setMessageDraft] = useState('');

  const liveDetails = useMemo(() => {
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
    setLogs((prev) => [
      { id: `log-${Date.now()}-${Math.random()}`, text, ts: new Date().toISOString() },
      ...prev
    ]);
  }, []);

  useEffect(() => {
    if (shouldConnect) {
      AudioSession.startAudioSession().catch((err) => logEvent(`Audio session error: ${(err as Error).message}`));
    } else {
      AudioSession.stopAudioSession().catch(() => undefined);
    }
    return () => {
      AudioSession.stopAudioSession().catch(() => undefined);
    };
  }, [shouldConnect, logEvent]);

  const handleFetch = useCallback(async () => {
    const sessionId = sessionInput.trim();
    if (!sessionId) {
      Alert.alert('Missing session', 'Enter a live session ID to continue.');
      return;
    }
    if (loading) return;
    setLoading(true);
    try {
      const res = await getLiveSession(sessionId, role, token);
      setResponse(res);
      logEvent(`Retrieved join token for role "${role}".`);
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to fetch live session');
      logEvent('Unable to retrieve join token.');
    } finally {
      setLoading(false);
    }
  }, [loading, logEvent, role, sessionInput, token]);

  const toggleRole = useCallback(() => {
    setRole((prev) => (prev === 'listener' ? 'host' : 'listener'));
  }, []);

  const handleJoin = useCallback(() => {
    if (!response) {
      Alert.alert('Missing token', 'Fetch the session details first.');
      return;
    }
    setShouldConnect(true);
    logEvent('Connecting to LiveKit room…');
  }, [logEvent, response]);

  const handleLeave = useCallback(() => {
    setShouldConnect(false);
    setRoomConnected(false);
    logEvent('Disconnected from LiveKit room.');
  }, [logEvent]);

  const handleSendLocalMessage = useCallback(() => {
    if (!messageDraft.trim()) return;
    logEvent(`(local) ${messageDraft.trim()}`);
    setMessageDraft('');
  }, [logEvent, messageDraft]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Join Live Session</Text>
        <Text style={styles.helper}>
          Request a temporary token from the backend, then connect to the LiveKit room to listen or act as a co-host.
        </Text>

        <Text style={styles.label}>Session ID</Text>
        <TextInput
          value={sessionInput}
          onChangeText={setSessionInput}
          placeholder="live session UUID"
          placeholderTextColor="#64748b"
          style={styles.input}
        />

        <View style={styles.buttonRow}>
          <Button title={`Role: ${role}`} onPress={toggleRole} />
          <Button title={loading ? 'Fetching…' : 'Fetch token'} onPress={handleFetch} disabled={loading} />
        </View>

        {liveDetails && (
          <View style={styles.section}>
            <Text style={styles.subheading}>Session Details</Text>
            <Text style={styles.info}>ID: {liveDetails.id}</Text>
            <Text style={styles.info}>Room: {liveDetails.room}</Text>
            <Text style={styles.info}>Title: {liveDetails.title}</Text>
            <Text style={styles.info}>Started: {liveDetails.startedAt}</Text>
            <Text style={styles.info}>Token: {liveDetails.token}</Text>
            <Text style={styles.info}>URL: {liveDetails.url}</Text>

            <View style={styles.buttonRow}>
              <Button title="Join audio" onPress={handleJoin} disabled={shouldConnect} />
              <Button title="Leave audio" onPress={handleLeave} disabled={!roomConnected && !shouldConnect} />
            </View>
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
                logEvent('Connected to LiveKit as listener.');
              }}
              onDisconnected={() => {
                setRoomConnected(false);
                setShouldConnect(false);
                logEvent('LiveKit connection closed.');
              }}
            >
              <View style={styles.liveControls}>
                <Text style={styles.liveStatus}>
                  You are connected as <Text style={styles.roleBadge}>{role}</Text>.
                </Text>
                <Text style={styles.info}>
                  Remote audio will play through the device speaker. Use the buttons above to disconnect when finished.
                </Text>
              </View>
            </LiveKitRoom>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.subheading}>Connection Status</Text>
          <Text style={styles.info}>
            {roomConnected ? 'Receiving live audio…' : shouldConnect ? 'Connecting…' : 'Disconnected'}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.subheading}>Quick Notes</Text>
          <View style={styles.chatRow}>
            <TextInput
              style={styles.chatInput}
              placeholder="Log a local note"
              placeholderTextColor="#64748b"
              value={messageDraft}
              onChangeText={setMessageDraft}
            />
            <Button title="Add" onPress={handleSendLocalMessage} />
          </View>
          <FlatList
            data={logs}
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
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 8
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
  roleBadge: {
    color: '#facc15',
    fontWeight: '700'
  },
  chatRow: {
    flexDirection: 'row',
    gap: 12,
    alignItems: 'center'
  },
  chatInput: {
    flex: 1,
    backgroundColor: '#0b1220',
    color: '#f8fafc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8
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

export default LiveListenerScreen;
