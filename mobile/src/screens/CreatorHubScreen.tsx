import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Image,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { theme } from '../theme/theme';

interface CreatorHubScreenProps {}

export const CreatorHubScreen: React.FC<CreatorHubScreenProps> = () => {
  const navigation = useNavigation();

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Creator Hub</Text>
        <Text style={styles.subtitle}>
          Turn your voice notes into viral shorts
        </Text>
      </View>

      {/* Quick Actions */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Quick Actions</Text>

        <TouchableOpacity
          style={styles.actionCard}
          onPress={() => navigation.navigate('CreateAudio')}
        >
          <View style={styles.actionIcon}>
            <Text style={styles.actionEmoji}>🎙️</Text>
          </View>
          <View style={styles.actionContent}>
            <Text style={styles.actionTitle}>Record New Note</Text>
            <Text style={styles.actionDescription}>
              Record a 60-120s voice note
            </Text>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.actionCard}
          onPress={() => {
            // TODO: Navigate to audiogram creation
          }}
        >
          <View style={styles.actionIcon}>
            <Text style={styles.actionEmoji}>🎬</Text>
          </View>
          <View style={styles.actionContent}>
            <Text style={styles.actionTitle}>Create Audiogram</Text>
            <Text style={styles.actionDescription}>
              Turn your note into a short with captions
            </Text>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.actionCard}
          onPress={() => navigation.navigate('Explore')}
        >
          <View style={styles.actionIcon}>
            <Text style={styles.actionEmoji}>📊</Text>
          </View>
          <View style={styles.actionContent}>
            <Text style={styles.actionTitle}>View Analytics</Text>
            <Text style={styles.actionDescription}>
              See how your content performs
            </Text>
          </View>
        </TouchableOpacity>
      </View>

      {/* Daily Prompt */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Daily Prompt</Text>
        
        <View style={styles.promptCard}>
          <Text style={styles.promptEmoji}>💡</Text>
          <Text style={styles.promptText}>
            What's one thing you learned today that surprised you?
          </Text>
          <TouchableOpacity
            style={styles.promptButton}
            onPress={() => navigation.navigate('CreateAudio')}
          >
            <Text style={styles.promptButtonText}>Record Response</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Smart Clips */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Smart Clips</Text>
          <TouchableOpacity>
            <Text style={styles.sectionLink}>View All</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.infoCard}>
          <Text style={styles.infoIcon}>✨</Text>
          <Text style={styles.infoTitle}>Auto-generate clips</Text>
          <Text style={styles.infoDescription}>
            We automatically find the best 15-30s moments from your recordings
            and create shareable clips.
          </Text>
          <View style={styles.infoStats}>
            <View style={styles.infoStat}>
              <Text style={styles.infoStatValue}>0</Text>
              <Text style={styles.infoStatLabel}>Clips created</Text>
            </View>
            <View style={styles.infoStat}>
              <Text style={styles.infoStatValue}>0</Text>
              <Text style={styles.infoStatLabel}>Shared</Text>
            </View>
          </View>
        </View>
      </View>

      {/* Tips */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Creator Tips</Text>

        <View style={styles.tipCard}>
          <Text style={styles.tipNumber}>1</Text>
          <Text style={styles.tipTitle}>Record consistently</Text>
          <Text style={styles.tipDescription}>
            Post 2-3 notes per week to build your audience
          </Text>
        </View>

        <View style={styles.tipCard}>
          <Text style={styles.tipNumber}>2</Text>
          <Text style={styles.tipTitle}>Use Smart Clips</Text>
          <Text style={styles.tipDescription}>
            Share your best 20s clips to YouTube Shorts & Instagram
          </Text>
        </View>

        <View style={styles.tipCard}>
          <Text style={styles.tipNumber}>3</Text>
          <Text style={styles.tipTitle}>Engage with your Circle</Text>
          <Text style={styles.tipDescription}>
            Reply to comments and join relevant Circles
          </Text>
        </View>
      </View>

      {/* Share Card */}
      <View style={styles.section}>
        <View style={styles.shareCard}>
          <Text style={styles.shareEmoji}>🚀</Text>
          <Text style={styles.shareTitle}>
            Ready to go viral?
          </Text>
          <Text style={styles.shareDescription}>
            Turn your best take into a 20s clip with captions and share to YouTube Shorts in one tap
          </Text>
          <TouchableOpacity style={styles.shareButton}>
            <Text style={styles.shareButtonText}>Create Audiogram</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  header: {
    padding: theme.spacing.lg,
    paddingTop: theme.spacing.xl,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border.light,
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    fontSize: 16,
    color: theme.colors.text.secondary,
  },
  section: {
    padding: theme.spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  sectionLink: {
    fontSize: 14,
    color: theme.colors.brand.primary,
    fontWeight: '600',
  },
  actionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: theme.colors.brand.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.md,
  },
  actionEmoji: {
    fontSize: 28,
  },
  actionContent: {
    flex: 1,
  },
  actionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  actionDescription: {
    fontSize: 14,
    color: theme.colors.text.secondary,
  },
  promptCard: {
    padding: theme.spacing.lg,
    backgroundColor: theme.colors.brand.primaryLight,
    borderRadius: theme.borderRadius.md,
    borderWidth: 2,
    borderColor: theme.colors.brand.primary,
    alignItems: 'center',
  },
  promptEmoji: {
    fontSize: 48,
    marginBottom: theme.spacing.md,
  },
  promptText: {
    fontSize: 18,
    lineHeight: 28,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
    fontWeight: '500',
  },
  promptButton: {
    backgroundColor: theme.colors.brand.primary,
    paddingHorizontal: theme.spacing.xl,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
  },
  promptButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  infoCard: {
    padding: theme.spacing.lg,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
  },
  infoIcon: {
    fontSize: 48,
    marginBottom: theme.spacing.md,
  },
  infoTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  infoDescription: {
    fontSize: 14,
    lineHeight: 22,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
  },
  infoStats: {
    flexDirection: 'row',
    gap: theme.spacing.xl,
  },
  infoStat: {
    alignItems: 'center',
  },
  infoStatValue: {
    fontSize: 32,
    fontWeight: '700',
    color: theme.colors.brand.primary,
    marginBottom: 4,
  },
  infoStatLabel: {
    fontSize: 12,
    color: theme.colors.text.tertiary,
  },
  tipCard: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
  },
  tipNumber: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.brand.primary,
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    textAlign: 'center',
    lineHeight: 32,
    marginRight: theme.spacing.md,
  },
  tipTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: 4,
    flex: 1,
  },
  tipDescription: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    flex: 1,
  },
  shareCard: {
    padding: theme.spacing.xl,
    backgroundColor: theme.colors.brand.primary,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
  },
  shareEmoji: {
    fontSize: 64,
    marginBottom: theme.spacing.md,
  },
  shareTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#fff',
    marginBottom: theme.spacing.sm,
    textAlign: 'center',
  },
  shareDescription: {
    fontSize: 16,
    lineHeight: 24,
    color: '#fff',
    opacity: 0.9,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
  },
  shareButton: {
    backgroundColor: '#fff',
    paddingHorizontal: theme.spacing.xl,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
  },
  shareButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.brand.primary,
  },
});

