import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Dimensions,
  ScrollView,
  Pressable,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from 'react-i18next';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { Button } from '@components/atoms/Button';

type OnboardingScreenProps = {
  navigation: NativeStackNavigationProp<any>;
};

const { width: SCREEN_WIDTH } = Dimensions.get('window');

const ONBOARDING_KEY = '@amunx_onboarding_complete';

const OnboardingScreen: React.FC<OnboardingScreenProps> = ({ navigation }) => {
  const { t } = useTranslation();
  const scrollViewRef = useRef<ScrollView>(null);
  const [currentIndex, setCurrentIndex] = useState(0);

  const slides = [
    {
      icon: 'mic' as const,
      title: t('onboarding.slide1.title', { defaultValue: 'One-Tap Voice Notes' }),
      description: t('onboarding.slide1.description', {
        defaultValue: 'Record 1-minute voice notes with a single tap. No setup, no hassle.',
      }),
    },
    {
      icon: 'volume-high' as const,
      title: t('onboarding.slide2.title', { defaultValue: 'Auto Processing' }),
      description: t('onboarding.slide2.description', {
        defaultValue: 'AI removes noise, normalizes loudness, and enhances audio quality automatically.',
      }),
    },
    {
      icon: 'chatbubbles' as const,
      title: t('onboarding.slide3.title', { defaultValue: 'Live Streaming' }),
      description: t('onboarding.slide3.description', {
        defaultValue: 'Host live audio sessions with real-time comments and reactions.',
      }),
    },
    {
      icon: 'shield-checkmark' as const,
      title: t('onboarding.slide4.title', { defaultValue: 'Privacy First' }),
      description: t('onboarding.slide4.description', {
        defaultValue: 'Go anonymous, use voice masking, or keep episodes private. You control everything.',
      }),
    },
  ];

  const handleScroll = (event: any) => {
    const offsetX = event.nativeEvent.contentOffset.x;
    const index = Math.round(offsetX / SCREEN_WIDTH);
    setCurrentIndex(index);
  };

  const handleNext = () => {
    if (currentIndex < slides.length - 1) {
      scrollViewRef.current?.scrollTo({
        x: SCREEN_WIDTH * (currentIndex + 1),
        animated: true,
      });
    } else {
      handleComplete();
    }
  };

  const handleSkip = () => {
    handleComplete();
  };

  const handleComplete = async () => {
    try {
      await AsyncStorage.setItem(ONBOARDING_KEY, 'true');
      navigation.replace('Auth');
    } catch (error) {
      console.error('Failed to save onboarding status:', error);
      navigation.replace('Auth');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Skip Button */}
      {currentIndex < slides.length - 1 && (
        <Pressable onPress={handleSkip} style={styles.skipButton}>
          <Text style={styles.skipText}>{t('onboarding.skip', { defaultValue: 'Skip' })}</Text>
        </Pressable>
      )}

      {/* Slides */}
      <ScrollView
        ref={scrollViewRef}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        style={styles.scrollView}
      >
        {slides.map((slide, index) => (
          <View key={index} style={styles.slide}>
            <View style={styles.iconContainer}>
              <Ionicons name={slide.icon} size={80} color={theme.colors.brand.primary} />
            </View>
            <Text style={styles.title}>{slide.title}</Text>
            <Text style={styles.description}>{slide.description}</Text>
          </View>
        ))}
      </ScrollView>

      {/* Pagination Dots */}
      <View style={styles.pagination}>
        {slides.map((_, index) => (
          <View
            key={index}
            style={[
              styles.dot,
              index === currentIndex && styles.dotActive,
            ]}
          />
        ))}
      </View>

      {/* Next / Get Started Button */}
      <View style={styles.footer}>
        <Button
          title={
            currentIndex === slides.length - 1
              ? t('onboarding.getStarted', { defaultValue: 'Get Started' })
              : t('onboarding.next', { defaultValue: 'Next' })
          }
          onPress={handleNext}
          icon={
            currentIndex === slides.length - 1 ? (
              <Ionicons name="arrow-forward" size={20} color={theme.colors.text.inverse} />
            ) : undefined
          }
        />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
  },
  skipButton: {
    position: 'absolute',
    top: theme.space.lg,
    right: theme.space.lg,
    zIndex: 10,
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
  },
  skipText: {
    color: theme.colors.text.secondary,
    fontSize: 16,
    fontWeight: '600',
  },
  scrollView: {
    flex: 1,
  },
  slide: {
    width: SCREEN_WIDTH,
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: theme.space.xl,
    gap: theme.space.xl,
  },
  iconContainer: {
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: theme.colors.brand.primary + '22',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.space.xl,
    ...applyShadow(8),
  },
  title: {
    color: theme.colors.text.primary,
    fontSize: 32,
    fontWeight: '700',
    textAlign: 'center',
    lineHeight: 40,
  },
  description: {
    color: theme.colors.text.secondary,
    fontSize: 18,
    textAlign: 'center',
    lineHeight: 26,
    paddingHorizontal: theme.space.lg,
  },
  pagination: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: theme.space.sm,
    paddingVertical: theme.space.xl,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: theme.colors.surface.chip,
  },
  dotActive: {
    width: 24,
    backgroundColor: theme.colors.brand.primary,
  },
  footer: {
    paddingHorizontal: theme.space.xl,
    paddingBottom: theme.space.xl,
  },
});

export default OnboardingScreen;

/**
 * Helper function to check if onboarding is complete
 */
export async function isOnboardingComplete(): Promise<boolean> {
  try {
    const value = await AsyncStorage.getItem(ONBOARDING_KEY);
    return value === 'true';
  } catch {
    return false;
  }
}

