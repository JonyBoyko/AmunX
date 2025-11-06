import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { theme } from '../theme/theme';

interface VisibilitySelectorProps {
  value: 'private' | 'circles' | 'public';
  onChange: (value: 'private' | 'circles' | 'public') => void;
  onSelectCircles?: () => void;
}

export const VisibilitySelector: React.FC<VisibilitySelectorProps> = ({
  value,
  onChange,
  onSelectCircles,
}) => {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Visibility</Text>
      
      <TouchableOpacity
        style={[styles.option, value === 'private' && styles.optionSelected]}
        onPress={() => onChange('private')}
      >
        <Text style={styles.optionIcon}>🔒</Text>
        <View style={styles.optionContent}>
          <Text style={[styles.optionTitle, value === 'private' && styles.textSelected]}>
            Private
          </Text>
          <Text style={styles.optionDesc}>Only you can see this</Text>
        </View>
        {value === 'private' && <Text style={styles.checkmark}>✓</Text>}
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.option, value === 'circles' && styles.optionSelected]}
        onPress={() => {
          onChange('circles');
          onSelectCircles?.();
        }}
      >
        <Text style={styles.optionIcon}>👥</Text>
        <View style={styles.optionContent}>
          <Text style={[styles.optionTitle, value === 'circles' && styles.textSelected]}>
            Share to Circles
          </Text>
          <Text style={styles.optionDesc}>Visible in selected circles</Text>
        </View>
        {value === 'circles' && <Text style={styles.checkmark}>✓</Text>}
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.option, value === 'public' && styles.optionSelected]}
        onPress={() => onChange('public')}
      >
        <Text style={styles.optionIcon}>🌐</Text>
        <View style={styles.optionContent}>
          <Text style={[styles.optionTitle, value === 'public' && styles.textSelected]}>
            Public
          </Text>
          <Text style={styles.optionDesc}>Everyone can see on Explore</Text>
        </View>
        {value === 'public' && <Text style={styles.checkmark}>✓</Text>}
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: theme.spacing.md,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  optionSelected: {
    borderColor: theme.colors.brand.primary,
    backgroundColor: theme.colors.brand.primaryLight,
  },
  optionIcon: {
    fontSize: 24,
    marginRight: theme.spacing.sm,
  },
  optionContent: {
    flex: 1,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: 2,
  },
  optionDesc: {
    fontSize: 13,
    color: theme.colors.text.tertiary,
  },
  textSelected: {
    color: theme.colors.brand.primary,
  },
  checkmark: {
    fontSize: 20,
    color: theme.colors.brand.primary,
    fontWeight: 'bold',
  },
});

