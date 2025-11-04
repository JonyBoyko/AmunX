import React from 'react';
import { Text, View, StyleSheet } from 'react-native';
import { useTranslation } from 'react-i18next';
import { theme } from '@theme/theme';

type BadgeVariant =
  | 'public'
  | 'anon'
  | 'mask'
  | 'pro'
  | 'raw'
  | 'clean'
  | 'studio'
  | 'live';

type BadgeProps = {
  variant: BadgeVariant;
  label?: string;
};

export const Badge: React.FC<BadgeProps> = ({ variant, label }) => {
  const { t } = useTranslation();

  const labels: Record<BadgeVariant, string> = {
    public: t('badges.public'),
    anon: t('badges.anon'),
    mask: t('badges.mask'),
    pro: t('badges.pro'),
    raw: t('badges.raw'),
    clean: t('badges.clean'),
    studio: t('badges.studio'),
    live: t('badges.live'),
  };

  const text = label || labels[variant] || variant.toUpperCase();

  const getColors = () => {
    switch (variant) {
      case 'pro':
        return {
          bg: theme.colors.brand.primary,
          text: theme.colors.text.inverse,
          border: theme.colors.brand.primary,
        };
      case 'live':
        return {
          bg: theme.colors.state.danger + '33',
          text: theme.colors.state.danger,
          border: theme.colors.state.danger,
        };
      case 'anon':
        return {
          bg: 'rgba(168, 85, 247, 0.15)',
          text: '#d8b4fe',
          border: 'rgba(168, 85, 247, 0.3)',
        };
      case 'mask':
      case 'studio':
        return {
          bg: 'rgba(139, 92, 246, 0.15)',
          text: '#d8b4fe',
          border: 'rgba(139, 92, 246, 0.3)',
        };
      default:
        return {
          bg: 'transparent',
          text: theme.colors.text.secondary,
          border: theme.colors.surface.border,
        };
    }
  };

  const colors = getColors();

  return (
    <View
      style={[
        styles.base,
        {
          backgroundColor: colors.bg,
          borderColor: colors.border,
        },
      ]}
    >
      <Text style={[styles.text, { color: colors.text }]}>{text}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  base: {
    paddingVertical: theme.space.xs,
    paddingHorizontal: theme.space.sm,
    borderRadius: theme.radius.sm,
    borderWidth: 1,
    alignSelf: 'flex-start',
  },
  text: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
});

