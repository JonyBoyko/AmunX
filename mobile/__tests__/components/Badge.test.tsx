import React from 'react';
import { render } from '@testing-library/react-native';
import { Badge } from '@components/atoms/Badge';

// Mock useTranslation
jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: {
      language: 'en',
    },
  }),
}));

describe('Badge', () => {
  it('renders with PRO variant', () => {
    const { getByText } = render(<Badge variant="pro" />);
    expect(getByText('badges.pro')).toBeTruthy();
  });

  it('renders with custom label', () => {
    const { getByText } = render(<Badge variant="pro" label="Custom Label" />);
    expect(getByText('Custom Label')).toBeTruthy();
  });

  it('renders with LIVE variant', () => {
    const { getByText } = render(<Badge variant="live" />);
    expect(getByText('badges.live')).toBeTruthy();
  });

  it('renders with PUBLIC variant', () => {
    const { getByText } = render(<Badge variant="public" />);
    expect(getByText('badges.public')).toBeTruthy();
  });
});

