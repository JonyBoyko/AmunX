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
  useParticipants
} from '@livekit/react-native';
import type { ReceivedDataMessage } from '@livekit/react-native';

import { getLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';
import { decodeMessage, encodeMessage } from '@utils/dataMessages';

type LogEntry = {
  id: string;
  text: string;
  ts: string;
};

const REACTION_TOPIC = 'amunx.reaction';
const CHAT_TOPIC = 'amunx.chat';

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
      title: response.session.title ?? '',
      mask: (response.session.mask as 'none' | 'basic' | 'studio') ?? 'none'
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
    logEvent('Connecting to LiveKit room...');
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
            <Text style={styles.info}>Mask: {liveDetails.mask}</Text>
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
                <ListenerStats />
                <ReactionPanel onEvent={logEvent} />
                <ChatPanel onEvent={logEvent} />
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
            {roomConnected ? 'Receiving live audio...' : shouldConnect ? 'Connecting...' : 'Disconnected'}
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

const ListenerStats: React.FC = () => {
  const participants = useParticipants();
  const listenerCount = useMemo(
    () => (participants ? participants.filter((participant) => !participant.isLocal).length : 0),
    [participants]
  );

  return <Text style={styles.info}>Listeners connected: {listenerCount}</Text>;
};

const ReactionPanel: React.FC<{ onEvent: (text: string) => void }> = ({ onEvent }) => {
  const [lastReaction, setLastReaction] = useState<string | null>(null);
  const { send } = useDataChannel(REACTION_TOPIC, (msg: ReceivedDataMessage<typeof REACTION_TOPIC>) => {
    const decoded = decodeMessage(msg.payload);
    const actor = msg.from?.identity ?? 'Participant';
    if (decoded) {
      onEvent(`${actor} shared ${decoded}`);
      setLastReaction(decoded);
    }
  });

  const sendReaction = useCallback(
    async (reaction: string) => {
      try {
        await send(encodeMessage(reaction), { reliable: false });
        onEvent(`You sent ${reaction}`);
        setLastReaction(reaction);
      } catch (error: any) {
        Alert.alert('Reaction error', error?.message ?? 'Unable to send reaction');
      }
    },
    [onEvent, send]
  );

  const emojiOptions = ['\\u{1F44F}', '\\u{1F389}', '\\u{1F64C}', '\\u{1F602}'];

  return (
    <View style={styles.reactionSection}>
      <Text style={styles.liveStatus}>Send a reaction</Text>
      <View style={styles.reactionRow}>
        {emojiOptions.map((code) => {
          const rendered = code.replace(/\\u\\{([0-9A-Fa-f]+)\\}/g, (_, hex) =>
            String.fromCodePoint(parseInt(hex, 16))
          );
          return (
            <Button
              key={code}
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
    const author = msg.from?.identity ?? 'Participant';
    const entry = {
      id: `chat-${author}-${Date.now()}-${Math.random()}`,
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
      const entry = {
        id: `chat-self-${Date.now()}-${Math.random()}`,
        author: 'You',
        text,
        ts: new Date().toISOString()
      };
      setMessages((prev) => [entry, ...prev].slice(0, 50));
      onEvent(`You: ${text}`);
      setDraft('');
    } catch (error: any) {
      Alert.alert('Chat error', error?.message ?? 'Unable to send message');
    }
  }, [draft, onEvent, send]);

  return (
    <View style={styles.chatSection}>
      <Text style={styles.liveStatus}>Chat</Text>
      <View style={styles.chatInputRow}>
        <TextInput
          style={styles.chatInput}
          placeholder="Say hello"
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
  reactionSection: {
    gap: 8
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
    gap: 8
  },
  chatInputRow: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center'
  },
  chatMessages: {
    gap: 6
  },
  chatMessage: {
    color: '#f8fafc'
  },
  chatAuthor: {
    color: '#38bdf8',
    fontWeight: '600'
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
