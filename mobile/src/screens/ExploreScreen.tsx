import React, { useState, useCallback } from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  RefreshControl,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';

import { exploreAPI } from '../api/explore';
import { AudioCard } from '../components/AudioCard';
import { FilterChips } from '../components/FilterChips';
import { SkeletonCard } from '../components/SkeletonCard';
import { theme } from '../theme/theme';
import { recordFeedEvent } from '../api/events';

const { width } = Dimensions.get('window');
const CARD_WIDTH = (width - theme.spacing.md * 3) / 2;

interface ExploreScreenProps {
  navigation: any;
}

export const ExploreScreen: React.FC<ExploreScreenProps> = ({ navigation }) => {
  const [selectedTopics, setSelectedTopics] = useState<string[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  // Fetch explore feed
  const {
    data,
    isLoading,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useQuery({
    queryKey: ['explore', selectedTopics],
    queryFn: ({ pageParam }) =>
      exploreAPI.getFeed({
        cursor: pageParam,
        topics: selectedTopics.join(','),
        limit: 20,
      }),
    getNextPageParam: (lastPage) => lastPage.next_cursor,
  });

  // Handle refresh
  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  }, [refetch]);

  // Handle card press
  const handleCardPress = useCallback(
    (cardId: string, audioUrl: string) => {
      // Record impression event
      recordFeedEvent({
        audio_id: cardId,
        event: 'play',
        meta: { source: 'explore' },
      });

      // Navigate to Player
      navigation.navigate('Player', {
        audioId: cardId,
        audioUrl,
      });
    },
    [navigation]
  );

  // Handle card visible (for impression tracking)
  const handleCardVisible = useCallback((cardId: string) => {
    // Record impression after 1.5s
    setTimeout(() => {
      recordFeedEvent({
        audio_id: cardId,
        event: 'impression',
        meta: { source: 'explore' },
      });
    }, 1500);
  }, []);

  // Render card item
  const renderCard = useCallback(
    ({ item, index }: { item: any; index: number }) => (
      <AudioCard
        card={item}
        onPress={() => handleCardPress(item.id, item.audio_url)}
        onVisible={() => handleCardVisible(item.id)}
        style={[
          styles.card,
          {
            marginLeft: index % 2 === 0 ? 0 : theme.spacing.sm,
            marginRight: index % 2 === 0 ? theme.spacing.sm : 0,
          },
        ]}
      />
    ),
    [handleCardPress, handleCardVisible]
  );

  // Render skeleton loading
  if (isLoading) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <FilterChips
            selectedTopics={selectedTopics}
            onSelectTopic={(topic) =>
              setSelectedTopics((prev) =>
                prev.includes(topic)
                  ? prev.filter((t) => t !== topic)
                  : [...prev, topic]
              )
            }
          />
        </View>
        <FlatList
          data={Array(6).fill(null)}
          renderItem={() => <SkeletonCard width={CARD_WIDTH} />}
          keyExtractor={(_, i) => `skeleton-${i}`}
          numColumns={2}
          contentContainerStyle={styles.gridContent}
        />
      </View>
    );
  }

  // Flatten pages data
  const cards = data?.pages.flatMap((page) => page.cards) || [];

  return (
    <View style={styles.container}>
      {/* Header with filters */}
      <View style={styles.header}>
        <FilterChips
          selectedTopics={selectedTopics}
          onSelectTopic={(topic) =>
            setSelectedTopics((prev) =>
              prev.includes(topic)
                ? prev.filter((t) => t !== topic)
                : [...prev, topic]
            )
          }
        />
      </View>

      {/* Grid of cards */}
      <FlatList
        data={cards}
        renderItem={renderCard}
        keyExtractor={(item) => item.id}
        numColumns={2}
        contentContainerStyle={styles.gridContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        onEndReached={() => {
          if (hasNextPage && !isFetchingNextPage) {
            fetchNextPage();
          }
        }}
        onEndReachedThreshold={0.5}
        ListFooterComponent={() =>
          isFetchingNextPage ? (
            <View style={styles.loader}>
              <ActivityIndicator size="small" color={theme.colors.brand.primary} />
            </View>
          ) : null
        }
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
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.background.primary,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border.light,
  },
  gridContent: {
    padding: theme.spacing.md,
  },
  card: {
    marginBottom: theme.spacing.md,
  },
  loader: {
    paddingVertical: theme.spacing.lg,
    alignItems: 'center',
  },
});

