import React, { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  FlatList
} from 'react-native';

import { getLiveSession, type LiveSessionCreateResponse } from '@api/live';
import { useSession } from '@store/session';

type ChatEntry = { id: string; sender: string; text: string; ts: string };

const LiveListenerScreen: React.FC = () => {
  const { token } = useSession();

  const [sessionIdInput, setSessionIdInput] = useState('');
  const [role, setRole] = useState<'listener' | 'host'>('listener');
  const [loading, setLoading] = useState(false);
  const [session, setSession] = useState<LiveSessionCreateResponse | null>(null);
  const [chatInput, setChatInput] = useState('');
  const [messages, setMessages] = useState<ChatEntry[]>([]);

  const summary = useMemo(() => {
    if (!session) return null;
    return {
      id: session.session.id,
      room: session.session.room,
      token: session.token,
      url: session.url,
      startedAt: session.session.started_at,
      title: session.session.title ?? ''
    };
  }, [session]);

  const handleJoin = useCallback(async () => {
    const trimmed = sessionIdInput.trim();
    if (!trimmed) {
      Alert.alert('Missing session', 'Enter a session identifier to join.');
      return;
    }
    if (loading) return;
    setLoading(true);
    try {
      const res = await getLiveSession(trimmed, role, token);
      setSession(res);
      setMessages((prev) => [
        ...prev,
        {
          id: `sys-${Date.now()}`,
          sender: 'system',
          text: 'Connected to live room. This is a placeholder chat feed.',
          ts: new Date().toISOString()
        }
      ]);
    } catch (error: any) {
      Alert.alert('Error', error?.message ?? 'Failed to load live session');
    } finally {
      setLoading(false);
    }
  }, [loading, role, sessionIdInput, token]);

  const handleSend = useCallback(() => {
    if (!chatInput.trim()) return;
    const entry: ChatEntry = {
      id: `local-${Date.now()}`,
      sender: 'you',
      text: chatInput.trim(),
      ts: new Date().toISOString()
    };
    setChatInput('');
    setMessages((prev) => [entry, ...prev]);
  }, [chatInput]);

  const toggleRole = useCallback(() => {
    setRole((prev) => (prev === 'listener' ? 'host' : 'listener'));
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Join Live Session</Text>
        <Text style={styles.infoLine}>Use this screen to request a LiveKit token from the API.</Text>
        <Text style={styles.label}>Session ID</Text>
        <TextInput
          value={sessionIdInput}
          onChangeText={setSessionIdInput}
          placeholder="live session UUID"
          placeholderTextColor="#64748b"
          style={styles.input}
        />
        <Text style={styles.label}>Role</Text>
        <View style={styles.row}>
          <Button title={`Role: ${role}`} onPress={toggleRole} />
        </View>
        <Button title={loading ? 'Joining...' : 'Join Session'} onPress={handleJoin} disabled={loading} />

        {summary && (
          <View style={styles.section}>
            <Text style={styles.subheading}>Session Info</Text>
            <Text style={styles.caption}>ID: {summary.id}</Text>
            <Text style={styles.caption}>Room: {summary.room}</Text>
            <Text style={styles.caption}>Title: {summary.title}</Text>
            <Text style={styles.caption}>Started: {summary.startedAt}</Text>
            <Text style={styles.caption}>Token: {summary.token}</Text>
            <Text style={styles.caption}>URL: {summary.url}</Text>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.subheading}>Chat (local placeholder)</Text>
          <View style={styles.chatRow}>
            <TextInput
              style={styles.chatInput}
              placeholder="Say something"
              placeholderTextColor="#64748b"
              value={chatInput}
              onChangeText={setChatInput}
            />
            <Button title="Send" onPress={handleSend} />
          </View>
          <FlatList
            data={messages}
            keyExtractor={(item) => item.id}
            contentContainerStyle={{ gap: 8 }}
            renderItem={({ item }) => (
              <View style={styles.chatBubble}>
                <Text style={styles.chatSender}>{item.sender}</Text>
                <Text style={styles.chatText}>{item.text}</Text>
                <Text style={styles.chatTimestamp}>{new Date(item.ts).toLocaleTimeString()}</Text>
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
  infoLine: {
    color: '#cbd5f5'
  },
  label: {
    color: '#cbd5f5',
    fontSize: 14,
    marginTop: 12
  },
  input: {
    backgroundColor: '#1e293b',
    color: '#f1f5f9',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10
  },
  row: {
    flexDirection: 'row',
    gap: 12,
    alignItems: 'center'
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
  caption: {
    color: '#cbd5f5'
  },
  chatRow: {
    flexDirection: 'row',
    gap: 12,
    alignItems: 'center'
  },
  chatInput: {
    flex: 1,
    backgroundColor: '#0f172a',
    color: '#f8fafc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  chatBubble: {
    backgroundColor: '#0b1220',
    borderRadius: 12,
    padding: 12
  },
  chatSender: {
    color: '#38bdf8',
    fontWeight: '600'
  },
  chatText: {
    color: '#f8fafc',
    marginTop: 4
  },
  chatTimestamp: {
    color: '#64748b',
    fontSize: 12,
    marginTop: 4
  }
});

export default LiveListenerScreen;
