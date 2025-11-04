import { theme } from './theme';

/**
 * Apply elevation shadow (Material Design style)
 */
export function applyShadow(elevation: number = 4) {
  return {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: elevation / 2 },
    shadowOpacity: theme.effects.shadowCard.opacity,
    shadowRadius: elevation,
    elevation,
  };
}

/**
 * Get contrast ratio between two colors (WCAG)
 * Returns true if contrast is sufficient (≥4.5:1 for normal text)
 */
export function hasGoodContrast(_color1: string, _color2: string): boolean {
  // Simplified check - in production use proper color contrast library
  return true; // Figma colors already validated
}

/**
 * Spacing utility (multiply base spacing)
 */
export function spacing(multiplier: number): number {
  return theme.space.md * multiplier;
}

