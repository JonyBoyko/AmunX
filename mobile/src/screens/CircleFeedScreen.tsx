import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { circlesAPI } from '../api/circles';
import { theme } from '../theme/theme';

interface CircleFeedScreenProps {
  navigation: any;
  route: {
    params: {
      circleId: string;
      circleName: string;
    };
  };
}

export const CircleFeedScreen: React.FC<CircleFeedScreenProps> = ({
  navigation,
  route,
}) => {
  const { circleId, circleName } = route.params;
  const [refreshing, setRefreshing] = useState(false);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['circleFeed', circleId],
    queryFn: () => circlesAPI.getCircleFeed(circleId),
  });

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  }, [refetch]);

  const renderPost = useCallback(
    ({ item }: { item: any }) => (
      <TouchableOpacity
        style={styles.postCard}
        onPress={() =>
          navigation.navigate('Player', {
            audioId: item.id,
            audioUrl: item.audio_url,
          })
        }
      >
        <View style={styles.postHeader}>
          <Text style={styles.ownerName}>{item.owner.display_name}</Text>
          <Text style={styles.timestamp}>2h ago</Text>
        </View>

        {item.title && <Text style={styles.postTitle}>{item.title}</Text>}

        <View style={styles.postMeta}>
          <Text style={styles.duration}>
            🎙️ {Math.floor(item.duration_sec / 60)}:{item.duration_sec % 60}
          </Text>
          {item.reply_count > 0 && (
            <Text style={styles.replyCount}>💬 {item.reply_count} replies</Text>
          )}
        </View>
      </TouchableOpacity>
    ),
    [navigation]
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>{circleName}</Text>
        <TouchableOpacity
          style={styles.recordButton}
          onPress={() =>
            navigation.navigate('Record', {
              circleId,
            })
          }
        >
          <Text style={styles.recordButtonText}>🎙️ Record</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={data?.posts || []}
        renderItem={renderPost}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={() => (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>No posts yet</Text>
            <Text style={styles.emptySubtext}>Be the first to share!</Text>
          </View>
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border.light,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: theme.colors.text.primary,
  },
  recordButton: {
    backgroundColor: theme.colors.brand.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
  },
  recordButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  listContent: {
    padding: theme.spacing.md,
  },
  postCard: {
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  postHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  ownerName: {
    fontSize: 15,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  timestamp: {
    fontSize: 13,
    color: theme.colors.text.tertiary,
  },
  postTitle: {
    fontSize: 16,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  postMeta: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  duration: {
    fontSize: 13,
    color: theme.colors.text.secondary,
  },
  replyCount: {
    fontSize: 13,
    color: theme.colors.brand.primary,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl * 2,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  emptySubtext: {
    fontSize: 14,
    color: theme.colors.text.tertiary,
  },
});

