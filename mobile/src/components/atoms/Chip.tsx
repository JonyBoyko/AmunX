import React from 'react';
import { Text, Pressable, StyleSheet } from 'react-native';
import { theme } from '@theme/theme';

type ChipProps = {
  label: string;
  onPress?: () => void;
  selected?: boolean;
};

export const Chip: React.FC<ChipProps> = ({ label, onPress, selected }) => {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        selected && styles.selected,
        pressed && { opacity: 0.8 },
      ]}
    >
      <Text style={[styles.text, selected && styles.textSelected]}>
        {label}
      </Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  base: {
    paddingVertical: theme.space.xs + 2,
    paddingHorizontal: theme.space.md,
    borderRadius: theme.radius.md,
    backgroundColor: theme.colors.surface.chip,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
  },
  selected: {
    backgroundColor: theme.colors.brand.primary + '33',
    borderColor: theme.colors.brand.primary,
  },
  text: {
    fontSize: theme.type.caption.size,
    fontWeight: '500',
    color: theme.colors.text.secondary,
  },
  textSelected: {
    color: theme.colors.brand.primary,
    fontWeight: '600',
  },
});

