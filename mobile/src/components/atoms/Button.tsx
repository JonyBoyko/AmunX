import React from 'react';
import { Pressable, Text, StyleSheet, ViewStyle, ActivityIndicator } from 'react-native';
import { theme } from '@theme/theme';

type ButtonProps = {
  title: string;
  onPress?: () => void;
  kind?: 'primary' | 'secondary' | 'tonal';
  style?: ViewStyle;
  disabled?: boolean;
  loading?: boolean;
  icon?: React.ReactNode;
};

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  kind = 'primary',
  style,
  disabled,
  loading,
  icon,
}) => {
  const backgroundColor =
    kind === 'primary'
      ? theme.colors.brand.primary
      : kind === 'tonal'
      ? theme.colors.surface.chip
      : 'transparent';

  const textColor =
    kind === 'primary' ? theme.colors.text.inverse : theme.colors.text.primary;

  const borderColor =
    kind === 'secondary' ? theme.colors.surface.border : 'transparent';

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.base,
        { backgroundColor, borderColor },
        pressed && !disabled && { opacity: 0.85 },
        disabled && { opacity: 0.5 },
        style,
      ]}
      accessibilityRole="button"
      accessibilityState={{ disabled: disabled || loading }}
    >
      {loading ? (
        <ActivityIndicator
          size="small"
          color={kind === 'primary' ? theme.colors.text.inverse : theme.colors.brand.primary}
          testID="button-loading"
        />
      ) : (
        <>
          {icon}
          <Text style={[styles.text, { color: textColor }]}>{title}</Text>
        </>
      )}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    paddingVertical: theme.space.md,
    paddingHorizontal: theme.space.lg,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.space.sm,
    minHeight: 48, // Accessibility: min touch target
  },
  text: {
    fontSize: theme.type.body.size,
    fontWeight: '600',
    lineHeight: theme.type.body.lineHeight,
  },
});

