import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../theme/theme';

interface ConsentBannerProps {
  circleId: string;
  circleName: string;
  onConsent?: () => void;
}

const CONSENT_KEY_PREFIX = 'circle_recording_consent_';

export const ConsentBanner: React.FC<ConsentBannerProps> = ({
  circleId,
  circleName,
  onConsent,
}) => {
  const [visible, setVisible] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkConsent();
  }, [circleId]);

  const checkConsent = async () => {
    try {
      const consentKey = `${CONSENT_KEY_PREFIX}${circleId}`;
      const hasConsented = await AsyncStorage.getItem(consentKey);
      
      if (!hasConsented) {
        setVisible(true);
      }
    } catch (error) {
      console.error('Failed to check consent:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAcknowledge = async () => {
    try {
      const consentKey = `${CONSENT_KEY_PREFIX}${circleId}`;
      await AsyncStorage.setItem(consentKey, new Date().toISOString());
      
      setVisible(false);
      onConsent?.();

      // TODO: Send consent event to backend
      // await fetch('/consent/record', {
      //   method: 'POST',
      //   body: JSON.stringify({
      //     circle_id: circleId,
      //     consented_at: new Date().toISOString(),
      //   }),
      // });
    } catch (error) {
      console.error('Failed to record consent:', error);
    }
  };

  if (loading || !visible) {
    return null;
  }

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.icon}>🎙️</Text>
        <Text style={styles.title}>Recording enabled</Text>
        <Text style={styles.message}>
          By speaking in <Text style={styles.circleName}>{circleName}</Text> you
          consent to being recorded and published to Circle members.
        </Text>
      </View>
      
      <TouchableOpacity style={styles.button} onPress={handleAcknowledge}>
        <Text style={styles.buttonText}>I Understand</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.brand.primaryLight,
    borderWidth: 1,
    borderColor: theme.colors.brand.primary,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    marginHorizontal: theme.spacing.md,
    marginVertical: theme.spacing.sm,
  },
  content: {
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  icon: {
    fontSize: 32,
    marginBottom: theme.spacing.sm,
  },
  title: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
    textAlign: 'center',
  },
  message: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  circleName: {
    fontWeight: '600',
    color: theme.colors.brand.primary,
  },
  button: {
    backgroundColor: theme.colors.brand.primary,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    alignItems: 'center',
  },
  buttonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#fff',
  },
});

