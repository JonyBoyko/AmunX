import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Button } from '@components/atoms/Button';
import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';

type UndoToastProps = {
  seconds?: number;
  onUndo: () => void;
  onComplete?: () => void;
};

export const UndoToast: React.FC<UndoToastProps> = ({
  seconds = 10,
  onUndo,
  onComplete,
}) => {
  const { t } = useTranslation();
  const [timeLeft, setTimeLeft] = useState(seconds);
  const [progress] = useState(new Animated.Value(0));

  useEffect(() => {
    // Countdown timer
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          onComplete?.();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    // Progress bar animation
    Animated.timing(progress, {
      toValue: 1,
      duration: seconds * 1000,
      useNativeDriver: false,
    }).start();

    return () => clearInterval(timer);
  }, [seconds, progress, onComplete]);

  const progressPercent = progress.interpolate({
    inputRange: [0, 1],
    outputRange: ['0%', '100%'],
  });

  return (
    <View style={styles.wrap}>
      <View style={styles.toast}>
        <View style={styles.content}>
          <View style={styles.textContainer}>
            <Text style={styles.title}>{t('recorder.undo.title')}</Text>
            <Text style={styles.subtitle}>
              {t('recorder.undo.message', { seconds: timeLeft })}
            </Text>
          </View>
          <Button
            title={t('recorder.undo.action')}
            kind="secondary"
            onPress={onUndo}
            style={styles.button}
          />
        </View>

        {/* Progress bar */}
        <View style={styles.progressTrack}>
          <Animated.View
            style={[
              styles.progressFill,
              { width: progressPercent },
            ]}
          />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrap: {
    position: 'absolute',
    left: theme.space.lg,
    right: theme.space.lg,
    bottom: 24,
    zIndex: 1000,
  },
  toast: {
    backgroundColor: theme.colors.surface.raised,
    borderRadius: theme.radius.lg,
    padding: theme.space.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    ...applyShadow(8),
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: theme.space.md,
    marginBottom: theme.space.md,
  },
  textContainer: {
    flex: 1,
    gap: theme.space.xs,
  },
  title: {
    color: theme.colors.text.primary,
    fontSize: theme.type.body.size,
    fontWeight: '600',
    lineHeight: theme.type.body.lineHeight,
  },
  subtitle: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
    lineHeight: theme.type.caption.lineHeight,
  },
  button: {
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.sm,
    minHeight: 40,
  },
  progressTrack: {
    height: 3,
    backgroundColor: theme.colors.surface.chip,
    borderRadius: theme.radius.xs,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.brand.primary,
    borderRadius: theme.radius.xs,
  },
});

