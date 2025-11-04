import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  FlatList,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Button } from '@components/atoms/Button';
import { useSession } from '@store/session';
import { listTopics, followTopic, unfollowTopic, type Topic } from '@api/topics';

type TopicsScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const TopicsScreen: React.FC<TopicsScreenProps> = ({ navigation }) => {
  const { token } = useSession();
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [refreshing, setRefreshing] = useState(false);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['topics', token],
    queryFn: () => listTopics(token),
  });

  const followMutation = useMutation({
    mutationFn: ({ topicId }: { topicId: string }) => {
      if (!token) throw new Error('Unauthorized');
      return followTopic(token, topicId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topics'] });
    },
  });

  const unfollowMutation = useMutation({
    mutationFn: ({ topicId }: { topicId: string }) => {
      if (!token) throw new Error('Unauthorized');
      return unfollowTopic(token, topicId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topics'] });
    },
  });

  const handleRefresh = async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  };

  const handleTopicPress = (topicId: string) => {
    navigation.navigate('TopicDetail', { topicId });
  };

  const handleFollowToggle = async (topic: Topic) => {
    if (!token) {
      navigation.navigate('Auth');
      return;
    }

    if (topic.is_following) {
      await unfollowMutation.mutateAsync({ topicId: topic.id });
    } else {
      await followMutation.mutateAsync({ topicId: topic.id });
    }
  };

  const renderTopic = ({ item }: { item: Topic }) => (
    <Pressable
      onPress={() => handleTopicPress(item.id)}
      style={({ pressed }) => [styles.topicCard, pressed && styles.topicCardPressed]}
    >
      <View style={styles.topicIcon}>
        <Text style={styles.topicEmoji}>{item.name[0]?.toUpperCase() || '📁'}</Text>
      </View>

      <View style={styles.topicInfo}>
        <Text style={styles.topicName}>{item.name}</Text>
        <Text style={styles.topicDescription} numberOfLines={2}>
          {item.description}
        </Text>

        <View style={styles.topicMeta}>
          <View style={styles.topicMetaItem}>
            <Ionicons name="musical-notes-outline" size={14} color={theme.colors.text.secondary} />
            <Text style={styles.topicMetaText}>
              {item.episode_count || 0} {t('topics.episodes', { defaultValue: 'episodes' })}
            </Text>
          </View>

          <View style={styles.topicMetaItem}>
            <Ionicons name="people-outline" size={14} color={theme.colors.text.secondary} />
            <Text style={styles.topicMetaText}>
              {item.follower_count || 0} {t('topics.followers', { defaultValue: 'followers' })}
            </Text>
          </View>
        </View>
      </View>

      <Button
        title={
          item.is_following
            ? t('topics.following', { defaultValue: 'Following' })
            : t('topics.follow', { defaultValue: 'Follow' })
        }
        kind={item.is_following ? 'secondary' : 'primary'}
        onPress={(e) => {
          e?.stopPropagation();
          handleFollowToggle(item);
        }}
        style={styles.followButton}
      />
    </Pressable>
  );

  if (isLoading && !refreshing) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        </View>
      </SafeAreaView>
    );
  }

  const topics = data?.topics || [];

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Text style={styles.headerTitle}>{t('topics.title', { defaultValue: 'Topics' })}</Text>
        <View style={{ width: 40 }} />
      </View>

      {/* Topics List */}
      <FlatList
        data={topics}
        keyExtractor={(item) => item.id}
        renderItem={renderTopic}
        contentContainerStyle={styles.listContent}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={theme.colors.brand.primary}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Ionicons name="folder-open-outline" size={64} color={theme.colors.text.secondary} />
            <Text style={styles.emptyTitle}>
              {t('topics.empty.title', { defaultValue: 'No topics available' })}
            </Text>
            <Text style={styles.emptyText}>
              {t('topics.empty.message', { defaultValue: 'Topics will appear here once created' })}
            </Text>
          </View>
        }
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.space.md,
  },
  loadingText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.surface.border,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  listContent: {
    padding: theme.space.lg,
  },
  topicCard: {
    flexDirection: 'row',
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.lg,
    gap: theme.space.md,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(2),
  },
  topicCardPressed: {
    opacity: 0.8,
  },
  topicIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: theme.colors.brand.primaryContainer,
    alignItems: 'center',
    justifyContent: 'center',
  },
  topicEmoji: {
    fontSize: 28,
  },
  topicInfo: {
    flex: 1,
    gap: theme.space.xs,
  },
  topicName: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  topicDescription: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    lineHeight: 20,
  },
  topicMeta: {
    flexDirection: 'row',
    gap: theme.space.md,
    marginTop: theme.space.xs,
  },
  topicMetaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  topicMetaText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
  },
  followButton: {
    alignSelf: 'flex-start',
    minWidth: 100,
  },
  separator: {
    height: theme.space.md,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: theme.space.xxl * 2,
    gap: theme.space.md,
  },
  emptyTitle: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  emptyText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
    paddingHorizontal: theme.space.xl,
  },
});

export default TopicsScreen;

