/**
 * Application configuration
 * Centralized place for all config values
 */

export const config = {
  // API Configuration
  api: {
    baseUrl: process.env.API_BASE_URL || 'http://localhost:8080/api/v1',
  },

  // RevenueCat Configuration
  revenueCat: {
    apiKeyIOS: process.env.REVENUECAT_API_KEY_IOS || 'appl_YOUR_IOS_KEY_HERE',
    apiKeyAndroid: process.env.REVENUECAT_API_KEY_ANDROID || 'goog_YOUR_ANDROID_KEY_HERE',
  },

  // Expo Configuration
  expo: {
    projectId: process.env.EXPO_PROJECT_ID || 'YOUR_EXPO_PROJECT_ID',
  },

  // Sentry Configuration
  sentry: {
    dsn: process.env.SENTRY_DSN || '',
    enabled: !!process.env.SENTRY_DSN,
  },

  // PostHog Configuration
  posthog: {
    apiKey: process.env.POSTHOG_API_KEY || '',
    host: process.env.POSTHOG_HOST || 'https://app.posthog.com',
    enabled: !!process.env.POSTHOG_API_KEY,
  },

  // LiveKit Configuration
  livekit: {
    url: process.env.LIVEKIT_URL || 'ws://localhost:7880',
  },

  // Feature Flags
  features: {
    liveEnabled: process.env.FEATURE_LIVE_ENABLED !== 'false',
    commentsEnabled: process.env.FEATURE_COMMENTS_ENABLED !== 'false',
    reactionsEnabled: process.env.FEATURE_REACTIONS_ENABLED !== 'false',
    proSubscriptionsEnabled: process.env.FEATURE_PRO_SUBSCRIPTIONS_ENABLED !== 'false',
  },

  // Development Settings
  dev: {
    debugMode: process.env.DEBUG_MODE === 'true',
    logLevel: process.env.LOG_LEVEL || 'info',
  },

  // App Info
  app: {
    version: '1.0.0',
    buildNumber: 1,
    name: 'AmunX',
    displayName: 'AmunX - Voice Journal & Livecast',
  },
};

export default config;

