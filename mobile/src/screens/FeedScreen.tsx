import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  RefreshControl,
  ActivityIndicator,
  SafeAreaView,
  StatusBar,
  TouchableOpacity,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';

import { useFeed } from '@hooks/useFeed';
import { EpisodeCard } from '@components/EpisodeCard';
import { MiniPlayer } from '@components/MiniPlayer';
import { EmptyState } from '@components/EmptyState';
import { ErrorState } from '@components/ErrorState';
import { useSession } from '@store/session';
import type { FeedEpisode } from '@api/feed';
import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Ionicons } from '@expo/vector-icons';

type FeedScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const FeedScreen: React.FC<FeedScreenProps> = ({ navigation }) => {
  const { token } = useSession();
  const { t } = useTranslation();
  const {
    episodes,
    isLoading,
    isError,
    error,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    react,
  } = useFeed({ token });

  const [currentEpisode, setCurrentEpisode] = useState<FeedEpisode | null>(null);

  // Auto-refetch on screen focus
  useFocusEffect(
    useCallback(() => {
      refetch();
    }, [refetch])
  );

  const handleEpisodePress = (id: string) => {
    const episode = episodes.find((ep) => ep.id === id);
    if (episode?.audio_url) {
      setCurrentEpisode(episode);
    }
    navigation.navigate('Episode', { id });
  };

  const handleReact = (episodeId: string, type: string) => {
    react({ episodeId, type });
  };

  const handleExpandPlayer = (episodeId: string) => {
    navigation.navigate('Episode', { id: episodeId });
  };

  const handleEndReached = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  const renderFooter = () => {
    if (!isFetchingNextPage) return null;
    return (
      <View style={styles.footer}>
        <ActivityIndicator size="small" color={theme.colors.brand.primary} />
        <Text style={styles.footerText}>{t('feed.loadingMore')}</Text>
      </View>
    );
  };

  const renderEmpty = () => {
    if (isLoading) {
      return (
        <View style={styles.centerContainer}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.loadingText}>{t('feed.loading')}</Text>
        </View>
      );
    }

    if (isError) {
      return (
        <ErrorState
          message={error?.message || t('feed.error.message')}
          onRetry={() => refetch()}
        />
      );
    }

    return (
      <EmptyState
        icon="🎙️"
        title={t('feed.empty.message')}
        message=""
        actionLabel={t('feed.empty.action')}
        onAction={() => navigation.navigate('Recorder')}
      />
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t('feed.title')}</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('Recorder')}
          >
            <Text style={styles.headerButtonIcon}>🎙️</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('LiveHost')}
          >
            <Text style={styles.headerButtonIcon}>🔴</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('Profile')}
          >
            <Ionicons name="person-outline" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('Settings')}
          >
            <Ionicons name="settings-outline" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Episodes list */}
      <FlatList
        data={episodes}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <EpisodeCard
            episode={item}
            onPress={handleEpisodePress}
            onReact={handleReact}
          />
        )}
        contentContainerStyle={[
          styles.listContent,
          episodes.length === 0 && styles.listContentEmpty,
        ]}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        ListEmptyComponent={renderEmpty}
        ListFooterComponent={renderFooter}
        refreshControl={
        <RefreshControl
          refreshing={isLoading && episodes.length > 0}
          onRefresh={refetch}
          tintColor={theme.colors.brand.primary}
          colors={[theme.colors.brand.primary]}
        />
        }
        onEndReached={handleEndReached}
        onEndReachedThreshold={0.5}
        showsVerticalScrollIndicator={false}
      />

      {/* Mini Player (sticky bottom) */}
      <MiniPlayer episode={currentEpisode} onExpand={handleExpandPlayer} />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
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
  headerTitle: {
    color: theme.colors.text.primary,
    fontSize: theme.type.h1.size,
    fontWeight: theme.type.h1.weight,
    letterSpacing: -0.5,
  },
  headerActions: {
    flexDirection: 'row',
    gap: 8,
  },
  headerButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface.card,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(2),
  },
  headerButtonIcon: {
    fontSize: 18,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 100, // Space for mini player
  },
  listContentEmpty: {
    flexGrow: 1,
  },
  separator: {
    height: 16,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  loadingText: {
    color: theme.colors.text.secondary,
    fontSize: 15,
    fontWeight: '500',
  },
  footer: {
    paddingVertical: 24,
    alignItems: 'center',
    gap: theme.space.sm,
  },
  footerText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    fontWeight: '500',
  },
});

export default FeedScreen;

