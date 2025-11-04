import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Button, FlatList, SafeAreaView, StyleSheet, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';

import type { RootStackParamList } from '@navigation/RootNavigator';
import { getEpisodeById, type FeedEpisode } from '@api/feed';
import { listComments, postComment, type Comment } from '@api/comments';
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
        <View style={{ width: 64 }} />
      </View>

      <View style={styles.card}>
        <Text style={styles.meta}>Mask: {episode.mask}, Quality: {episode.quality}</Text>
        {episode.keywords && episode.keywords.length > 0 && (
          <Text style={styles.meta}>Keywords: {episode.keywords.join(', ')}</Text>
        )}
        <Button title="Play" onPress={() => { /* TODO: integrate player */ }} />
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
              <Text style={styles.commentMeta}>{new Date(item.created_at).toLocaleString()}</Text>
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
  row: { flexDirection: 'row', gap: 8, alignItems: 'center' },
  input: { flex: 1, backgroundColor: '#0f172a', color: '#f8fafc', borderRadius: 8, paddingHorizontal: 12, height: 40 },
  comment: { backgroundColor: '#0b1220', borderRadius: 12, padding: 12 },
  commentText: { color: '#f8fafc' },
  commentMeta: { color: '#64748b', fontSize: 12, marginTop: 4 }
});

export default EpisodeScreen;

