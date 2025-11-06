import React from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import { theme } from '../theme/theme';

const POPULAR_TOPICS = [
  'technology',
  'startup',
  'business',
  'ai',
  'design',
  'productivity',
  'health',
  'music',
  'education',
  'entertainment',
];

interface FilterChipsProps {
  selectedTopics: string[];
  onSelectTopic: (topic: string) => void;
}

export const FilterChips: React.FC<FilterChipsProps> = ({
  selectedTopics,
  onSelectTopic,
}) => {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}
    >
      {POPULAR_TOPICS.map((topic) => {
        const isSelected = selectedTopics.includes(topic);
        return (
          <TouchableOpacity
            key={topic}
            style={[styles.chip, isSelected && styles.chipSelected]}
            onPress={() => onSelectTopic(topic)}
            activeOpacity={0.7}
          >
            <Text style={[styles.chipText, isSelected && styles.chipTextSelected]}>
              {topic}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: theme.spacing.xs,
  },
  chip: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.background.tertiary,
    borderRadius: theme.borderRadius.full,
    marginRight: theme.spacing.sm,
    borderWidth: 1,
    borderColor: theme.colors.border.light,
  },
  chipSelected: {
    backgroundColor: theme.colors.brand.primary,
    borderColor: theme.colors.brand.primary,
  },
  chipText: {
    fontSize: 14,
    fontWeight: '500',
    color: theme.colors.text.primary,
  },
  chipTextSelected: {
    color: '#fff',
  },
});

