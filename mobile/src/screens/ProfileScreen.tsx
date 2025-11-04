import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  ScrollView,
  ActivityIndicator,
  FlatList,
  RefreshControl,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Badge } from '@components/atoms/Badge';
import { Button } from '@components/atoms/Button';
import { EpisodeCard } from '@components/EpisodeCard';
import { useSession } from '@store/session';
import { useFeed } from '@hooks/useFeed';
import type { FeedEpisode } from '@api/feed';

type ProfileScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const ProfileScreen: React.FC<ProfileScreenProps> = ({ navigation }) => {
  const { user, token } = useSession();
  const { t } = useTranslation();
  const { episodes, isLoading, refetch } = useFeed({ token });
  const [refreshing, setRefreshing] = useState(false);

  // Filter episodes by current user
  const myEpisodes = episodes.filter((ep) => ep.author_id === user?.id);

  const handleRefresh = async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  };

  const handleEpisodePress = (id: string) => {
    navigation.navigate('Episode', { id });
  };

  const handleEditProfile = () => {
    // TODO: Navigate to Edit Profile screen
    navigation.navigate('Settings');
  };

  const stats = {
    totalEpisodes: myEpisodes.length,
    totalListens: myEpisodes.reduce((sum, ep) => sum + (ep.plays || 0), 0),
    totalReactions: myEpisodes.reduce((sum, ep) => sum + (ep.reactions_count || 0), 0),
  };

  const isPro = user?.is_pro || false;

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

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Text style={styles.headerTitle}>{t('profile.title', { defaultValue: 'Profile' })}</Text>
        <Pressable onPress={() => navigation.navigate('Settings')} style={styles.settingsButton}>
          <Ionicons name="settings-outline" size={24} color={theme.colors.text.primary} />
        </Pressable>
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={theme.colors.brand.primary}
          />
        }
      >
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <View style={styles.avatarLarge}>
            <Text style={styles.avatarLargeText}>
              {user?.email?.[0]?.toUpperCase() || 'U'}
            </Text>
          </View>

          <View style={styles.profileInfo}>
            <Text style={styles.profileName}>
              {user?.email?.split('@')[0] || t('profile.guest', { defaultValue: 'Guest' })}
            </Text>
            <Text style={styles.profileEmail}>{user?.email || ''}</Text>

            <View style={styles.badgeRow}>
              {isPro && <Badge variant="pro" />}
            </View>
          </View>

          <Button
            title={t('profile.editProfile', { defaultValue: 'Edit Profile' })}
            kind="secondary"
            onPress={handleEditProfile}
            style={styles.editButton}
          />

          {!isPro && (
            <Button
              title={t('profile.upgradeToPro', { defaultValue: 'Upgrade to PRO' })}
              onPress={() => navigation.navigate('Paywall')}
              style={styles.upgradeButton}
            />
          )}
        </View>

        {/* Stats */}
        <View style={styles.statsCard}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{stats.totalEpisodes}</Text>
            <Text style={styles.statLabel}>
              {t('profile.stats.episodes', { defaultValue: 'Episodes' })}
            </Text>
          </View>

          <View style={styles.statDivider} />

          <View style={styles.statItem}>
            <Text style={styles.statValue}>{stats.totalListens}</Text>
            <Text style={styles.statLabel}>
              {t('profile.stats.listens', { defaultValue: 'Listens' })}
            </Text>
          </View>

          <View style={styles.statDivider} />

          <View style={styles.statItem}>
            <Text style={styles.statValue}>{stats.totalReactions}</Text>
            <Text style={styles.statLabel}>
              {t('profile.stats.reactions', { defaultValue: 'Reactions' })}
            </Text>
          </View>
        </View>

        {/* My Episodes */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>
            {t('profile.myEpisodes', { defaultValue: 'My Episodes' })} ({myEpisodes.length})
          </Text>

          {myEpisodes.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="mic-outline" size={64} color={theme.colors.text.secondary} />
              <Text style={styles.emptyTitle}>
                {t('profile.noEpisodes.title', { defaultValue: 'No episodes yet' })}
              </Text>
              <Text style={styles.emptyText}>
                {t('profile.noEpisodes.message', {
                  defaultValue: 'Start recording to see your episodes here',
                })}
              </Text>
              <Button
                title={t('profile.recordFirst', { defaultValue: 'Record your first episode' })}
                onPress={() => navigation.navigate('Recorder')}
                style={styles.recordButton}
              />
            </View>
          ) : (
            <View style={styles.episodesList}>
              {myEpisodes.map((episode) => (
                <EpisodeCard
                  key={episode.id}
                  episode={episode}
                  onPress={handleEpisodePress}
                  showAuthor={false}
                />
              ))}
            </View>
          )}
        </View>
      </ScrollView>
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
  settingsButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    padding: theme.space.lg,
    gap: theme.space.xl,
    paddingBottom: theme.space.xxl * 2,
  },
  profileCard: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.xl,
    gap: theme.space.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(4),
    alignItems: 'center',
  },
  avatarLarge: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(8),
  },
  avatarLargeText: {
    color: theme.colors.text.inverse,
    fontSize: 40,
    fontWeight: '700',
  },
  profileInfo: {
    alignItems: 'center',
    gap: theme.space.xs,
  },
  profileName: {
    color: theme.colors.text.primary,
    fontSize: 24,
    fontWeight: '700',
  },
  profileEmail: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
  },
  badgeRow: {
    flexDirection: 'row',
    gap: theme.space.xs,
    marginTop: theme.space.sm,
  },
  editButton: {
    width: '100%',
  },
  upgradeButton: {
    width: '100%',
  },
  statsCard: {
    flexDirection: 'row',
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    padding: theme.space.xl,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(4),
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
    gap: theme.space.xs,
  },
  statValue: {
    color: theme.colors.text.primary,
    fontSize: 28,
    fontWeight: '700',
  },
  statLabel: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    textAlign: 'center',
  },
  statDivider: {
    width: 1,
    backgroundColor: theme.colors.surface.border,
    marginHorizontal: theme.space.md,
  },
  section: {
    gap: theme.space.md,
  },
  sectionTitle: {
    color: theme.colors.text.primary,
    fontSize: 20,
    fontWeight: '600',
  },
  episodesList: {
    gap: theme.space.lg,
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
  recordButton: {
    marginTop: theme.space.lg,
  },
});

export default ProfileScreen;

