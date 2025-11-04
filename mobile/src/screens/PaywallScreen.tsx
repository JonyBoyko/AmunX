import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';
import type { PurchasesPackage } from 'react-native-purchases';

import { theme } from '@theme/theme';
import { Button } from '@components/atoms/Button';
import { Badge } from '@components/atoms/Badge';
import { applyShadow } from '@theme/utils';
import { useRevenueCat } from '@hooks/useRevenueCat';

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
  const { offerings, isPro, loading: rcLoading, purchasing, purchase, restore } = useRevenueCat();
  const [selectedPackage, setSelectedPackage] = useState<PurchasesPackage | null>(null);

  const PRO_FEATURES = getProFeatures(t);

  // Auto-select yearly package by default
  useEffect(() => {
    if (offerings?.availablePackages) {
      const yearlyPackage = offerings.availablePackages.find(
        (pkg) => pkg.identifier === '$rc_annual' || pkg.packageType === 'ANNUAL'
      );
      setSelectedPackage(yearlyPackage || offerings.availablePackages[0]);
    }
  }, [offerings]);

  const handleSubscribe = async () => {
    if (!selectedPackage) {
      Alert.alert(t('common.error'), 'Please select a subscription plan');
      return;
    }

    const success = await purchase(selectedPackage);
    
    if (success) {
      Alert.alert(t('paywall.thankYou.title'), t('paywall.thankYou.message'));
      navigation.goBack();
    }
  };

  const handleRestore = async () => {
    const success = await restore();
    if (success) {
      navigation.goBack();
    }
  };

  if (rcLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        </View>
      </SafeAreaView>
    );
  }

  const packages = offerings?.availablePackages || [];

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

              {packages.length === 0 ? (
                <Text style={styles.noPackagesText}>
                  {t('paywall.noPackages', { defaultValue: 'No subscription plans available' })}
                </Text>
              ) : (
                packages.map((pkg) => {
                  const isSelected = selectedPackage?.identifier === pkg.identifier;
                  const isYearly = pkg.identifier.includes('annual') || pkg.packageType === 'ANNUAL';
                  
                  return (
                    <Pressable
                      key={pkg.identifier}
                      onPress={() => setSelectedPackage(pkg)}
                      style={[
                        styles.planCard,
                        isSelected && styles.planCardSelected,
                      ]}
                    >
                      <View style={styles.planRadio}>
                        {isSelected && <View style={styles.planRadioSelected} />}
                      </View>
                      <View style={styles.planInfo}>
                        <Text style={styles.planName}>
                          {pkg.product.title || (isYearly ? 'Annual' : 'Monthly')}
                        </Text>
                        <Text style={styles.planPrice}>
                          {pkg.product.priceString} / {isYearly ? 'year' : 'month'}
                        </Text>
                        {isYearly && (
                          <Text style={styles.planSubtext}>
                            {t('paywall.pricing.yearly.subtitle', { defaultValue: 'Best value!' })}
                          </Text>
                        )}
                      </View>
                      {isYearly && (
                        <View style={styles.planBadge}>
                          <Text style={styles.planBadgeText}>
                            {t('paywall.pricing.yearly.badge', { defaultValue: 'Save 40%' })}
                          </Text>
                        </View>
                      )}
                    </Pressable>
                  );
                })
              )}

            {/* CTA */}
            <Button
              title={
                purchasing
                  ? t('paywall.processing', { defaultValue: 'Processing...' })
                  : t('paywall.cta', { defaultValue: 'Subscribe Now' })
              }
              onPress={handleSubscribe}
              loading={purchasing}
              style={styles.ctaButton}
              disabled={!selectedPackage || packages.length === 0}
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
  noPackagesText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
    paddingVertical: theme.space.xl,
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

