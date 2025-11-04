import React, { useMemo } from 'react';
import { ActivityIndicator, Button, FlatList, SafeAreaView, StyleSheet, Text, View } from 'react-native';

import { useFeedQuery } from '@api/feed';
import type { FeedEpisode } from '@api/feed';
import { useSession } from '@store/session';

const FeedItem: React.FC<{ episode: FeedEpisode }> = ({ episode }) => {
  const title = episode.summary ?? 'Voice note';
  const published = episode.published_at ? new Date(episode.published_at).toLocaleString() : 'Pending';

  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.meta}>Mask: {episode.mask}, Quality: {episode.quality}</Text>
      <Text style={styles.meta}>Published: {published}</Text>
      {episode.keywords && episode.keywords.length > 0 && <Text style={styles.meta}>Keywords: {episode.keywords.join(', ')}</Text>}
      <Button title="Play" onPress={() => {}} />
    </View>
  );
};

const HomeScreen: React.FC = ({ navigation }: any) => {
  const { token } = useSession();
  const query = useFeedQuery(token);

  const items = useMemo(() => query.data?.items ?? [], [query.data]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Your Feed</Text>
        <Button title="Record" onPress={() => navigation.navigate('Recorder')} />
      </View>

      {query.isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator />
        </View>
      ) : query.isError ? (
        <View style={styles.center}>
          <Text style={styles.error}>Failed to load feed.</Text>
          <Button title="Retry" onPress={() => query.refetch()} />
        </View>
      ) : (
        <FlatList
          data={items}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
          ItemSeparatorComponent={() => <View style={styles.separator} />}
          renderItem={({ item }) => <FeedItem episode={item} />}
        />
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0f172a'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16
  },
  headerTitle: {
    color: '#f8fafc',
    fontSize: 20,
    fontWeight: '700'
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center'
  },
  error: {
    color: '#f87171',
    marginBottom: 12
  },
  list: {
    paddingHorizontal: 16,
    paddingBottom: 24
  },
  separator: {
    height: 12
  },
  card: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 16,
    gap: 8
  },
  cardTitle: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '600'
  },
  meta: {
    color: '#cbd5f5'
  }
});

export default HomeScreen;
