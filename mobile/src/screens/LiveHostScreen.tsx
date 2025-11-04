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

import {
  AudioSession,
  LiveKitRoom,
  useDataChannel,
  useLocalParticipant,
  useParticipants
} from '@livekit/react-native';
import type { ReceivedDataMessage } from '@livekit/react-native';
import { useQueryClient } from '@tanstack/react-query';

import { createLiveSession, endLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';
import { decodeMessage, encodeMessage } from '@utils/dataMessages';

type EventLogEntry = {
  id: string;
  text: string;
  ts: string;
};

const MASK_OPTIONS: Array<{ label: string; value: 'none' | 'basic' | 'studio' }> = [
  { label: 'None', value: 'none' },
  { label: 'Basic', value: 'basic' },
  { label: 'Studio', value: 'studio' }
];

const REACTION_TOPIC = 'amunx.reaction';
const CHAT_TOPIC = 'amunx.chat';

const LiveHostScreen: React.FC = () => {
  const { token } = useSession();
  const queryClient = useQueryClient();

  const [topicId, setTopicId] = useState('');
  const [title, setTitle] = useState('');
  const [recordingKey, setRecordingKey] = useState('');
  const [duration, setDuration] = useState('');
  const [mask, setMask] = useState<'none' | 'basic' | 'studio'>('none');
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
      title: response.session.title ?? '',
      mask: (response.session.mask as 'none' | 'basic' | 'studio') ?? 'none'
    };
  }, [response]);

  useEffect(() => {
    if (liveSummary) {
      const next = liveSummary.mask || 'none';
      setMask(next);
    }
  }, [liveSummary?.mask]);

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
        title: title.trim() || undefined,
        mask
      };
      const res = await createLiveSession(token, payload);
      setResponse(res);
      setShouldConnect(true);
      logEvent(`Live session created (mask: ${mask}). Connecting as host...`);
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
      await queryClient.invalidateQueries({ queryKey: ['feed'] });
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
    logEvent('Connecting to LiveKit room...');
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
        <Button title={isStarting ? 'Starting...' : 'Start Live'} onPress={handleStart} disabled={isStarting} />

        {liveSummary && (
          <View style={styles.section}>
            <Text style={styles.subheading}>Session Info</Text>
            <Text style={styles.info}>ID: {liveSummary.id}</Text>
            <Text style={styles.info}>Room: {liveSummary.room}</Text>
            <Text style={styles.info}>Title: {liveSummary.title}</Text>
            <Text style={styles.info}>Mask: {liveSummary.mask}</Text>
            <Text style={styles.info}>Started: {liveSummary.startedAt}</Text>
            <Text style={styles.info}>Token: {liveSummary.token}</Text>
            <Text style={styles.info}>URL: {liveSummary.url}</Text>

            <View style={styles.maskRow}>
              <Text style={styles.maskLabel}>Live mask (beta)</Text>
              <View style={styles.maskButtons}>
                {MASK_OPTIONS.map((option) => (
                  <Button
                    key={option.value}
                    title={option.label}
                    onPress={() => {
                      setMask(option.value);
                      logEvent(`Mask preference changed to ${option.value}.`);
                    }}
                    color={mask === option.value ? '#38bdf8' : undefined}
                  />
                ))}
              </View>
              <Text style={styles.maskNote}>
                Mask is applied to the published audio track. Real-time masking will fall back to post-processing if
                the device cannot keep up.
              </Text>
            </View>

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
              title={isEnding ? 'Ending...' : 'End Live'}
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
              <ReactionPalette onEvent={logEvent} />
              <ChatPanel onEvent={logEvent} />
              <HostControls onEnd={handleEnd} />
            </LiveKitRoom>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.subheading}>Connection Status</Text>
          <Text style={styles.info}>
            {roomConnected ? 'Streaming live audio...' : shouldConnect ? 'Connecting...' : 'Not connected'}
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
  const participants = useParticipants();
  const listenerCount = useMemo(
    () => (participants ? participants.filter((participant) => !participant.isLocal).length : 0),
    [participants]
  );
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
      <Text style={styles.listenerCount}>Listeners connected: {listenerCount}</Text>
      <Button title={micEnabled ? 'Mute microphone' : 'Unmute microphone'} onPress={toggleMic} />
      <Button title="End session" color="#ef4444" onPress={onEnd} />
    </View>
  );
};

const ReactionPalette: React.FC<{ onEvent: (text: string) => void }> = ({ onEvent }) => {
  const [lastReaction, setLastReaction] = useState<string | null>(null);
  const { send } = useDataChannel(REACTION_TOPIC, (msg: ReceivedDataMessage<typeof REACTION_TOPIC>) => {
    const decoded = decodeMessage(msg.payload);
    const actor = msg.from?.identity ?? 'Listener';
    if (decoded) {
      onEvent(`${actor} reacted with ${decoded}`);
      setLastReaction(decoded);
    }
  });

  const sendReaction = useCallback(
    async (reaction: string) => {
      try {
        await send(encodeMessage(reaction), { reliable: false });
        onEvent(`You reacted with ${reaction}`);
        setLastReaction(reaction);
      } catch (error: any) {
        Alert.alert('Reaction error', error?.message ?? 'Failed to send reaction');
      }
    },
    [onEvent, send]
  );

  return (
    <View style={styles.reactionSection}>
      <Text style={styles.liveStatus}>Quick Reactions</Text>
      <View style={styles.reactionRow}>
        {['\\u{1F44F}', '\\u{1F525}', '\\u{2764}\\u{FE0F}', '\\u{1F602}'].map((emoji) => {
          const rendered = emoji.replace(/\\u\\{([0-9A-Fa-f]+)\\}/g, (_, hex) =>
            String.fromCodePoint(parseInt(hex, 16))
          );
          return (
            <Button
              key={emoji}
              title={rendered}
              onPress={() => void sendReaction(rendered)}
            />
          );
        })}
      </View>
      {lastReaction && <Text style={styles.reactionNote}>Last reaction: {lastReaction}</Text>}
    </View>
  );
};

const ChatPanel: React.FC<{ onEvent: (text: string) => void }> = ({ onEvent }) => {
  const [messages, setMessages] = useState<Array<{ id: string; author: string; text: string; ts: string }>>([]);
  const [draft, setDraft] = useState('');
  const { send } = useDataChannel(CHAT_TOPIC, (msg: ReceivedDataMessage<typeof CHAT_TOPIC>) => {
    const decoded = decodeMessage(msg.payload);
    if (!decoded) return;
    const author = msg.from?.identity ?? 'Listener';
    const entry = {
      id: `chat-${msg.from?.identity ?? 'anon'}-${Date.now()}-${Math.random()}`,
      author,
      text: decoded,
      ts: new Date().toISOString()
    };
    setMessages((prev) => [entry, ...prev].slice(0, 50));
    onEvent(`${author}: ${decoded}`);
  });

  const handleSend = useCallback(async () => {
    const text = draft.trim();
    if (!text) return;
    try {
      await send(encodeMessage(text), { reliable: true });
      const selfEntry = {
        id: `chat-self-${Date.now()}-${Math.random()}`,
        author: 'You',
        text,
        ts: new Date().toISOString()
      };
      setMessages((prev) => [selfEntry, ...prev].slice(0, 50));
      onEvent(`You: ${text}`);
      setDraft('');
    } catch (error: any) {
      Alert.alert('Chat error', error?.message ?? 'Failed to send message');
    }
  }, [draft, onEvent, send]);

  return (
    <View style={styles.chatSection}>
      <Text style={styles.liveStatus}>Chat</Text>
      <View style={styles.chatInputRow}>
        <TextInput
          style={styles.chatInput}
          placeholder="Say something"
          placeholderTextColor="#64748b"
          value={draft}
          onChangeText={setDraft}
          autoCapitalize="sentences"
        />
        <Button title="Send" onPress={handleSend} />
      </View>
      {messages.length > 0 && (
        <View style={styles.chatMessages}>
          {messages.map((msg) => (
            <Text key={msg.id} style={styles.chatMessage}>
              <Text style={styles.chatAuthor}>{msg.author}: </Text>
              {msg.text}
            </Text>
          ))}
        </View>
      )}
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
  maskRow: {
    gap: 8
  },
  maskLabel: {
    color: '#cbd5f5',
    fontWeight: '600'
  },
  maskButtons: {
    flexDirection: 'row',
    gap: 8
  },
  maskNote: {
    color: '#94a3b8',
    fontSize: 12
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
  listenerCount: {
    color: '#cbd5f5'
  },
  reactionSection: {
    gap: 8,
    marginBottom: 12
  },
  reactionRow: {
    flexDirection: 'row',
    gap: 12
  },
  reactionNote: {
    color: '#cbd5f5',
    fontSize: 12
  },
  chatSection: {
    gap: 8,
    marginBottom: 12
  },
  chatInputRow: {
    flexDirection: 'row',
    gap: 8,
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
  chatMessages: {
    gap: 6
  },
  chatMessage: {
    color: '#f8fafc'
  },
  chatAuthor: {
    fontWeight: '600',
    color: '#38bdf8'
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

