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
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';

import { theme } from '@theme/theme';
import { Button } from '@components/atoms/Button';
import { Badge } from '@components/atoms/Badge';

type PaywallScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const getProFeatures = (t: any) => [
  {
    icon: 'document-text-outline',
    title: t('paywall.features.transcription.title'),
    description: t('paywall.features.transcription.description'),
  },
  {
    icon: 'sparkles-outline',
    title: t('paywall.features.summary.title'),
    description: t('paywall.features.summary.description'),
  },
  {
    icon: 'mic-outline',
    title: t('paywall.features.maskPro.title'),
    description: t('paywall.features.maskPro.description'),
  },
  {
    icon: 'musical-notes-outline',
    title: t('paywall.features.studio.title'),
    description: t('paywall.features.studio.description'),
  },
  {
    icon: 'stats-chart-outline',
    title: t('paywall.features.analytics.title'),
    description: t('paywall.features.analytics.description'),
  },
  {
    icon: 'flash-outline',
    title: t('paywall.features.priority.title'),
    description: t('paywall.features.priority.description'),
  },
];

const PaywallScreen: React.FC<PaywallScreenProps> = ({ navigation }) => {
  const { t } = useTranslation();
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly');
  const [loading, setLoading] = useState(false);

  const PRO_FEATURES = getProFeatures(t);

  const handleSubscribe = async () => {
    setLoading(true);
    // TODO: Integrate Stripe/RevenueCat
    await new Promise((resolve) => setTimeout(resolve, 2000));
    setLoading(false);
    Alert.alert(t('paywall.thankYou.title'), t('paywall.thankYou.message'));
    navigation.goBack();
  };

  const handleRestore = async () => {
    // TODO: Restore purchases
    Alert.alert(t('paywall.restoring.title'), t('paywall.restoring.message'));
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.closeButton}>
          <Ionicons name="close" size={28} color={theme.colors.text.primary} />
        </Pressable>
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Hero */}
        <View style={styles.hero}>
          <Badge variant="pro" />
          <Text style={styles.heroTitle}>{t('paywall.title')}</Text>
          <Text style={styles.heroSubtitle}>
            {t('paywall.subtitle')}
          </Text>
        </View>

        {/* Features */}
        <View style={styles.features}>
          {PRO_FEATURES.map((feature, index) => (
            <View key={index} style={styles.featureCard}>
              <View style={styles.featureIcon}>
                <Ionicons
                  name={feature.icon as any}
                  size={28}
                  color={theme.colors.brand.primary}
                />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>{feature.title}</Text>
                <Text style={styles.featureDescription}>{feature.description}</Text>
              </View>
            </View>
          ))}
        </View>

        {/* Pricing */}
        <View style={styles.pricing}>
          <Text style={styles.pricingTitle}>{t('paywall.pricing.title')}</Text>

          {/* Monthly Plan */}
          <Pressable
            onPress={() => setSelectedPlan('monthly')}
            style={[
              styles.planCard,
              selectedPlan === 'monthly' && styles.planCardSelected,
            ]}
          >
            <View style={styles.planRadio}>
              {selectedPlan === 'monthly' && <View style={styles.planRadioSelected} />}
            </View>
            <View style={styles.planInfo}>
              <Text style={styles.planName}>{t('paywall.pricing.monthly.name')}</Text>
              <Text style={styles.planPrice}>{t('paywall.pricing.monthly.price')}</Text>
            </View>
          </Pressable>

          {/* Yearly Plan */}
          <Pressable
            onPress={() => setSelectedPlan('yearly')}
            style={[
              styles.planCard,
              selectedPlan === 'yearly' && styles.planCardSelected,
            ]}
          >
            <View style={styles.planRadio}>
              {selectedPlan === 'yearly' && <View style={styles.planRadioSelected} />}
            </View>
            <View style={styles.planInfo}>
              <Text style={styles.planName}>{t('paywall.pricing.yearly.name')}</Text>
              <Text style={styles.planPrice}>{t('paywall.pricing.yearly.price')}</Text>
              <Text style={styles.planSubtext}>{t('paywall.pricing.yearly.subtitle')}</Text>
            </View>
            <View style={styles.planBadge}>
              <Text style={styles.planBadgeText}>{t('paywall.pricing.yearly.badge')}</Text>
            </View>
          </Pressable>
        </View>

        {/* CTA */}
        <Button
          title={loading ? t('paywall.processing') : t('paywall.cta')}
          onPress={handleSubscribe}
          loading={loading}
          style={styles.ctaButton}
        />

        {/* Fine Print */}
        <View style={styles.finePrint}>
          <Pressable onPress={handleRestore}>
            <Text style={styles.restoreLink}>{t('paywall.restore')}</Text>
          </Pressable>
          <Text style={styles.finePrintText}>
            {t('paywall.finePrint')}
          </Text>
          <View style={styles.legalLinks}>
            <Text style={styles.legalLink}>{t('paywall.legal.terms')}</Text>
            <Text style={styles.legalDivider}>•</Text>
            <Text style={styles.legalLink}>{t('paywall.legal.privacy')}</Text>
          </View>
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
    alignItems: 'flex-end',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
  },
  closeButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    paddingHorizontal: theme.space.lg,
    paddingBottom: theme.space.xxl,
    gap: theme.space.xxl,
  },
  hero: {
    alignItems: 'center',
    gap: theme.space.md,
    paddingTop: theme.space.lg,
  },
  heroTitle: {
    color: theme.colors.text.primary,
    fontSize: 32,
    fontWeight: '700',
    textAlign: 'center',
    lineHeight: 40,
  },
  heroSubtitle: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
    lineHeight: theme.type.body.lineHeight,
  },
  features: {
    gap: theme.space.md,
  },
  featureCard: {
    flexDirection: 'row',
    gap: theme.space.md,
    padding: theme.space.lg,
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
  },
  featureIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: theme.colors.brand.primary + '22',
    alignItems: 'center',
    justifyContent: 'center',
  },
  featureText: {
    flex: 1,
    gap: theme.space.xs,
  },
  featureTitle: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  featureDescription: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    lineHeight: theme.type.caption.lineHeight,
  },
  pricing: {
    gap: theme.space.md,
  },
  pricingTitle: {
    color: theme.colors.text.primary,
    fontSize: theme.type.h2.size,
    fontWeight: theme.type.h2.weight,
    textAlign: 'center',
  },
  planCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.space.md,
    padding: theme.space.lg,
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.md,
    borderWidth: 2,
    borderColor: theme.colors.surface.border,
  },
  planCardSelected: {
    borderColor: theme.colors.brand.primary,
    backgroundColor: theme.colors.brand.primary + '11',
  },
  planRadio: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: theme.colors.surface.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  planRadioSelected: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: theme.colors.brand.primary,
  },
  planInfo: {
    flex: 1,
    gap: 2,
  },
  planName: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  planPrice: {
    color: theme.colors.text.primary,
    fontSize: 20,
    fontWeight: '700',
  },
  planSubtext: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
  },
  planBadge: {
    position: 'absolute',
    top: -10,
    right: theme.space.md,
    backgroundColor: theme.colors.brand.accent,
    paddingHorizontal: theme.space.sm,
    paddingVertical: theme.space.xs,
    borderRadius: theme.radius.sm,
  },
  planBadgeText: {
    color: theme.colors.text.inverse,
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  ctaButton: {
    marginTop: theme.space.md,
  },
  finePrint: {
    alignItems: 'center',
    gap: theme.space.md,
  },
  restoreLink: {
    color: theme.colors.brand.primary,
    fontSize: theme.type.caption.size,
    fontWeight: '600',
  },
  finePrintText: {
    color: theme.colors.text.secondary,
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 16,
  },
  legalLinks: {
    flexDirection: 'row',
    gap: theme.space.sm,
  },
  legalLink: {
    color: theme.colors.text.secondary,
    fontSize: 12,
    textDecorationLine: 'underline',
  },
  legalDivider: {
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
});

export default PaywallScreen;

