/**
 * Test setup file
 * Runs before all tests
 */

import '@testing-library/jest-native/extend-expect';

// Mock AsyncStorage
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

// Mock expo-localization
jest.mock('expo-localization', () => ({
  locale: 'en-US',
  locales: ['en-US'],
  timezone: 'America/Los_Angeles',
  isoCurrencyCodes: ['USD'],
  region: 'US',
  getLocales: () => [
    {
      languageCode: 'en',
      languageTag: 'en-US',
      regionCode: 'US',
      textDirection: 'ltr',
    },
  ],
}));

// Mock expo-av
jest.mock('expo-av', () => ({
  Audio: {
    requestPermissionsAsync: jest.fn(),
    setAudioModeAsync: jest.fn(),
    Recording: {
      createAsync: jest.fn(),
    },
  },
  RecordingOptionsPresets: {
    HIGH_QUALITY: {},
  },
}));

// Mock expo-notifications
jest.mock('expo-notifications', () => ({
  setNotificationHandler: jest.fn(),
  getPermissionsAsync: jest.fn(() => Promise.resolve({ status: 'granted' })),
  requestPermissionsAsync: jest.fn(() => Promise.resolve({ status: 'granted' })),
  getExpoPushTokenAsync: jest.fn(() => Promise.resolve({ data: 'test-token' })),
  addNotificationReceivedListener: jest.fn(),
  addNotificationResponseReceivedListener: jest.fn(),
  removeNotificationSubscription: jest.fn(),
}));

// Mock react-native-purchases
jest.mock('react-native-purchases', () => ({
  setLogLevel: jest.fn(),
  configure: jest.fn(),
  getOfferings: jest.fn(() => Promise.resolve({ current: null })),
  purchasePackage: jest.fn(),
  restorePurchases: jest.fn(),
  getCustomerInfo: jest.fn(() =>
    Promise.resolve({ entitlements: { active: {} } })
  ),
  logOut: jest.fn(),
  logIn: jest.fn(),
  LOG_LEVEL: {
    DEBUG: 'DEBUG',
  },
}));

// Mock @livekit/react-native
jest.mock('@livekit/react-native', () => ({
  LiveKitRoom: jest.fn(() => null),
  useLocalParticipant: jest.fn(() => ({
    localParticipant: null,
  })),
  useParticipants: jest.fn(() => []),
  useDataChannel: jest.fn(() => ({
    send: jest.fn(),
  })),
  AudioSession: {
    startAudioSession: jest.fn(),
    stopAudioSession: jest.fn(),
  },
}));

// Suppress console warnings in tests
global.console = {
  ...console,
  warn: jest.fn(),
  error: jest.fn(),
};

