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
import type { RouteProp } from '@react-navigation/native';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Button } from '@components/atoms/Button';
import { EpisodeCard } from '@components/EpisodeCard';
import { useSession } from '@store/session';
import { getTopic, followTopic, unfollowTopic } from '@api/topics';
import { useFeed } from '@hooks/useFeed';

type TopicDetailScreenProps = {
  navigation: NativeStackNavigationProp<any>;
  route: RouteProp<{ params: { topicId: string } }>;
};

const TopicDetailScreen: React.FC<TopicDetailScreenProps> = ({ navigation, route }) => {
  const { topicId } = route.params;
  const { token } = useSession();
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [refreshing, setRefreshing] = useState(false);

  const { data: topic, isLoading: topicLoading } = useQuery({
    queryKey: ['topic', topicId, token],
    queryFn: () => getTopic(topicId, token),
  });

  const { episodes, isLoading: episodesLoading, refetch } = useFeed({ token, topicId });

  const followMutation = useMutation({
    mutationFn: () => {
      if (!token) throw new Error('Unauthorized');
      return followTopic(token, topicId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topic', topicId] });
      queryClient.invalidateQueries({ queryKey: ['topics'] });
    },
  });

  const unfollowMutation = useMutation({
    mutationFn: () => {
      if (!token) throw new Error('Unauthorized');
      return unfollowTopic(token, topicId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topic', topicId] });
      queryClient.invalidateQueries({ queryKey: ['topics'] });
    },
  });

  const handleRefresh = async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  };

  const handleEpisodePress = (id: string) => {
    navigation.navigate('Episode', { id });
  };

  const handleFollowToggle = async () => {
    if (!token) {
      navigation.navigate('Auth');
      return;
    }

    if (topic?.is_following) {
      await unfollowMutation.mutateAsync();
    } else {
      await followMutation.mutateAsync();
    }
  };

  if (topicLoading || episodesLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!topic) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <Text style={styles.errorText}>{t('topics.notFound', { defaultValue: 'Topic not found' })}</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Text style={styles.headerTitle}>{topic.name}</Text>
        <View style={{ width: 40 }} />
      </View>

      <FlatList
        data={episodes}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <EpisodeCard episode={item} onPress={handleEpisodePress} />
        )}
        contentContainerStyle={styles.listContent}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={theme.colors.brand.primary}
          />
        }
        ListHeaderComponent={
          <View style={styles.topicHeader}>
            <View style={styles.topicIcon}>
              <Text style={styles.topicEmoji}>{topic.name[0]?.toUpperCase() || '📁'}</Text>
            </View>

            <Text style={styles.topicName}>{topic.name}</Text>
            <Text style={styles.topicDescription}>{topic.description}</Text>

            <View style={styles.topicMeta}>
              <View style={styles.metaItem}>
                <Ionicons name="musical-notes-outline" size={16} color={theme.colors.text.secondary} />
                <Text style={styles.metaText}>
                  {topic.episode_count || 0} {t('topics.episodes', { defaultValue: 'episodes' })}
                </Text>
              </View>

              <View style={styles.metaItem}>
                <Ionicons name="people-outline" size={16} color={theme.colors.text.secondary} />
                <Text style={styles.metaText}>
                  {topic.follower_count || 0} {t('topics.followers', { defaultValue: 'followers' })}
                </Text>
              </View>
            </View>

            <Button
              title={
                topic.is_following
                  ? t('topics.unfollow', { defaultValue: 'Unfollow' })
                  : t('topics.follow', { defaultValue: 'Follow' })
              }
              kind={topic.is_following ? 'secondary' : 'primary'}
              onPress={handleFollowToggle}
              style={styles.followButton}
              icon={
                <Ionicons
                  name={topic.is_following ? 'checkmark-circle-outline' : 'add-circle-outline'}
                  size={20}
                  color={topic.is_following ? theme.colors.text.primary : theme.colors.text.inverse}
                />
              }
            />

            <Text style={styles.episodesTitle}>
              {t('topics.latestEpisodes', { defaultValue: 'Latest Episodes' })}
            </Text>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Ionicons name="mic-off-outline" size={64} color={theme.colors.text.secondary} />
            <Text style={styles.emptyTitle}>
              {t('topics.noEpisodes.title', { defaultValue: 'No episodes yet' })}
            </Text>
            <Text style={styles.emptyText}>
              {t('topics.noEpisodes.message', {
                defaultValue: 'Be the first to post an episode in this topic!',
              })}
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
  errorText: {
    color: theme.colors.state.danger,
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
  topicHeader: {
    alignItems: 'center',
    marginBottom: theme.space.xl,
    gap: theme.space.md,
  },
  topicIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: theme.colors.brand.primaryContainer,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.space.sm,
    ...applyShadow(4),
  },
  topicEmoji: {
    fontSize: 40,
  },
  topicName: {
    color: theme.colors.text.primary,
    fontSize: 28,
    fontWeight: '700',
    textAlign: 'center',
  },
  topicDescription: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: theme.space.lg,
  },
  topicMeta: {
    flexDirection: 'row',
    gap: theme.space.xl,
    marginTop: theme.space.sm,
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  metaText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
  },
  followButton: {
    marginTop: theme.space.md,
    minWidth: 200,
  },
  episodesTitle: {
    color: theme.colors.text.primary,
    fontSize: 20,
    fontWeight: '600',
    alignSelf: 'flex-start',
    marginTop: theme.space.xl,
  },
  separator: {
    height: theme.space.lg,
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

export default TopicDetailScreen;

