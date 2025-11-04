import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  ScrollView,
  Alert,
  Switch,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Button } from '@components/atoms/Button';
import { Badge } from '@components/atoms/Badge';
import { useSession } from '@store/session';
import { setLanguage } from '@i18n/index';

type SettingsScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const SettingsScreen: React.FC<SettingsScreenProps> = ({ navigation }) => {
  const { user, clearSession } = useSession();
  const { t } = useTranslation();
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [autoplay, setAutoplay] = useState(true);
  const [analyticsEnabled, setAnalyticsEnabled] = useState(true);

  const isPro = user?.is_pro || false;

  const handleLanguageChange = async (lng: string) => {
    await setLanguage(lng);
  };

  const handleLogout = () => {
    Alert.alert(t('settings.dangerZone.logoutConfirm.title'), t('settings.dangerZone.logoutConfirm.message'), [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('settings.dangerZone.logout'),
        style: 'destructive',
        onPress: () => {
          clearSession();
          navigation.reset({ index: 0, routes: [{ name: 'Auth' }] });
        },
      },
    ]);
  };

  const handleDeleteAccount = () => {
    Alert.alert(
      t('settings.dangerZone.deleteConfirm.title'),
      t('settings.dangerZone.deleteConfirm.message'),
      [
        { text: t('common.cancel'), style: 'cancel' },
        {
          text: t('common.delete'),
          style: 'destructive',
          onPress: async () => {
            // TODO: Call delete API
            Alert.alert(t('settings.dangerZone.deleted.title'), t('settings.dangerZone.deleted.message'));
            clearSession();
            navigation.reset({ index: 0, routes: [{ name: 'Auth' }] });
          },
        },
      ]
    );
  };

  const renderSettingRow = (
    icon: string,
    label: string,
    value?: React.ReactNode,
    onPress?: () => void
  ) => (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.settingRow,
        pressed && styles.settingRowPressed,
      ]}
      disabled={!onPress}
    >
      <View style={styles.settingLeft}>
        <View style={styles.settingIcon}>
          <Ionicons name={icon as any} size={22} color={theme.colors.text.primary} />
        </View>
        <Text style={styles.settingLabel}>{label}</Text>
      </View>
      {value}
      {onPress && (
        <Ionicons
          name="chevron-forward"
          size={20}
          color={theme.colors.text.secondary}
        />
      )}
    </Pressable>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <Text style={styles.headerTitle}>{t('settings.title')}</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {user?.email?.[0]?.toUpperCase() || 'U'}
            </Text>
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.profileEmail}>{user?.email || t('settings.profile.guest')}</Text>
            <View style={styles.profileBadges}>
              {isPro && <Badge variant="pro" />}
            </View>
          </View>
          {!isPro && (
            <Button
              title={t('settings.profile.upgrade')}
              kind="tonal"
              onPress={() => navigation.navigate('Paywall')}
              style={styles.upgradeButton}
            />
          )}
        </View>

        {/* Account Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.account.title')}</Text>
          <View style={styles.card}>
            {renderSettingRow('person-outline', t('settings.account.profile'), undefined, () => {
              Alert.alert(t('settings.account.profile'), t('settings.account.comingSoon'));
            })}
            {renderSettingRow('key-outline', t('settings.account.changeEmail'), undefined, () => {
              Alert.alert(t('settings.account.changeEmail'), t('settings.account.comingSoon'));
            })}
            {isPro &&
              renderSettingRow(
                'card-outline',
                t('settings.account.manageSubscription'),
                undefined,
                () => {
                  Alert.alert(t('settings.account.manageSubscription'), t('settings.account.comingSoon'));
                }
              )}
          </View>
        </View>

        {/* Preferences */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.preferences.title')}</Text>
          <View style={styles.card}>
            {renderSettingRow(
              'notifications-outline',
              t('settings.preferences.notifications'),
              <Switch
                value={notificationsEnabled}
                onValueChange={setNotificationsEnabled}
                trackColor={{
                  false: theme.colors.surface.chip,
                  true: theme.colors.brand.primary,
                }}
                thumbColor="#fff"
              />
            )}
            {renderSettingRow(
              'play-outline',
              t('settings.preferences.autoplay'),
              <Switch
                value={autoplay}
                onValueChange={setAutoplay}
                trackColor={{
                  false: theme.colors.surface.chip,
                  true: theme.colors.brand.primary,
                }}
                thumbColor="#fff"
              />
            )}
            {renderSettingRow(
              'analytics-outline',
              t('settings.preferences.analytics'),
              <Switch
                value={analyticsEnabled}
                onValueChange={setAnalyticsEnabled}
                trackColor={{
                  false: theme.colors.surface.chip,
                  true: theme.colors.brand.primary,
                }}
                thumbColor="#fff"
              />
            )}
            {renderSettingRow(
              'language-outline',
              t('settings.preferences.language'),
              undefined,
              () => {
                Alert.alert(
                  t('settings.preferences.language'),
                  '',
                  [
                    {
                      text: t('settings.languages.en'),
                      onPress: () => handleLanguageChange('en'),
                    },
                    {
                      text: t('settings.languages.uk'),
                      onPress: () => handleLanguageChange('uk'),
                    },
                    { text: t('common.cancel'), style: 'cancel' },
                  ]
                );
              }
            )}
          </View>
        </View>

        {/* Support */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.support.title')}</Text>
          <View style={styles.card}>
            {renderSettingRow('help-circle-outline', t('settings.support.help'), undefined, () => {
              Alert.alert(t('settings.support.help'), 'help@amunx.app');
            })}
            {renderSettingRow('document-text-outline', t('settings.support.terms'), undefined, () => {
              Alert.alert(t('settings.support.terms'), 'Terms of Service');
            })}
            {renderSettingRow('shield-checkmark-outline', t('settings.support.privacy'), undefined, () => {
              Alert.alert(t('settings.support.privacy'), 'Privacy Policy');
            })}
          </View>
        </View>

        {/* Danger Zone */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.dangerZone.title')}</Text>
          <View style={styles.card}>
            <Button
              title={t('settings.dangerZone.logout')}
              kind="secondary"
              onPress={handleLogout}
              icon={<Ionicons name="log-out-outline" size={18} color={theme.colors.text.primary} />}
            />
            <Button
              title={t('settings.dangerZone.deleteAccount')}
              kind="secondary"
              onPress={handleDeleteAccount}
              icon={<Ionicons name="trash-outline" size={18} color={theme.colors.state.danger} />}
              style={{ borderColor: theme.colors.state.danger }}
            />
          </View>
        </View>

        {/* App Info */}
        <View style={styles.appInfo}>
          <Text style={styles.appVersion}>{t('settings.appInfo.version')}</Text>
          <Text style={styles.appCopyright}>{t('settings.appInfo.copyright')}</Text>
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
    fontSize: theme.type.h2.size,
    fontWeight: theme.type.h2.weight,
  },
  content: {
    padding: theme.space.lg,
    gap: theme.space.xl,
  },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.space.md,
    padding: theme.space.lg,
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(4),
  },
  avatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: theme.colors.text.inverse,
    fontSize: 24,
    fontWeight: '700',
  },
  profileInfo: {
    flex: 1,
    gap: theme.space.xs,
  },
  profileEmail: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  profileBadges: {
    flexDirection: 'row',
    gap: theme.space.xs,
  },
  upgradeButton: {
    paddingHorizontal: theme.space.md,
    paddingVertical: theme.space.sm,
    minHeight: 36,
  },
  section: {
    gap: theme.space.md,
  },
  sectionTitle: {
    color: theme.colors.text.secondary,
    fontSize: 14,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    paddingHorizontal: theme.space.xs,
  },
  card: {
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    overflow: 'hidden',
    gap: 1,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    backgroundColor: theme.colors.surface.card,
    gap: theme.space.md,
  },
  settingRowPressed: {
    backgroundColor: theme.colors.surface.chip,
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.space.md,
    flex: 1,
  },
  settingIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface.chip,
    alignItems: 'center',
    justifyContent: 'center',
  },
  settingLabel: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '500',
  },
  appInfo: {
    alignItems: 'center',
    gap: theme.space.xs,
    paddingTop: theme.space.lg,
    paddingBottom: theme.space.xxl,
  },
  appVersion: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    fontWeight: '600',
  },
  appCopyright: {
    color: theme.colors.text.secondary,
    fontSize: 11,
  },
});

export default SettingsScreen;

