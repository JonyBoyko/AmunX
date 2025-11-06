import React from 'react';
import { View, StyleSheet, Animated } from 'react-native';
import { theme } from '../theme/theme';

interface SkeletonCardProps {
  width: number;
}

export const SkeletonCard: React.FC<SkeletonCardProps> = ({ width }) => {
  const animatedValue = React.useRef(new Animated.Value(0)).current;

  React.useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(animatedValue, {
          toValue: 1,
          duration: 1000,
          useNativeDriver: true,
        }),
        Animated.timing(animatedValue, {
          toValue: 0,
          duration: 1000,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [animatedValue]);

  const opacity = animatedValue.interpolate({
    inputRange: [0, 1],
    outputRange: [0.3, 0.7],
  });

  return (
    <View style={[styles.container, { width }]}>
      <Animated.View style={[styles.waveform, { opacity }]} />
      <View style={styles.content}>
        <View style={styles.ownerRow}>
          <Animated.View style={[styles.avatar, { opacity }]} />
          <Animated.View style={[styles.ownerName, { opacity }]} />
        </View>
        <Animated.View style={[styles.textLine, { opacity }]} />
        <Animated.View style={[styles.textLine, { opacity, width: '80%' }]} />
        <Animated.View style={[styles.textLine, { opacity, width: '60%' }]} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    overflow: 'hidden',
    marginBottom: theme.spacing.md,
  },
  waveform: {
    height: 100,
    backgroundColor: theme.colors.border.light,
  },
  content: {
    padding: theme.spacing.sm,
  },
  ownerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  avatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: theme.colors.border.light,
    marginRight: theme.spacing.xs,
  },
  ownerName: {
    width: 80,
    height: 12,
    borderRadius: 6,
    backgroundColor: theme.colors.border.light,
  },
  textLine: {
    height: 12,
    borderRadius: 6,
    backgroundColor: theme.colors.border.light,
    marginBottom: theme.spacing.xs,
  },
});

