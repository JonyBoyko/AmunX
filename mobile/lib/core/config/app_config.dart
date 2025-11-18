class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // 10.0.2.2 exposes the host machine inside Android emulator/Chrome web runner
    defaultValue: 'http://10.0.2.2:8080/v1',
  );

  // LiveKit Configuration
  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );

  // RevenueCat Configuration
  static const String revenueCatApiKeyIOS = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: 'appl_YOUR_IOS_KEY_HERE',
  );
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: 'goog_YOUR_ANDROID_KEY_HERE',
  );

  // Sentry Configuration
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static bool get sentryEnabled => sentryDsn.isNotEmpty;

  // PostHog Configuration
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );
  static bool get posthogEnabled => posthogApiKey.isNotEmpty;

  // Feature Flags
  static const bool liveEnabled = true;
  static const bool commentsEnabled = true;
  static const bool reactionsEnabled = true;
  static const bool proSubscriptionsEnabled = true;
  static const bool smartInboxFallbackEnabled = bool.fromEnvironment(
    'SMART_INBOX_FALLBACK',
    defaultValue: true,
  );

  // App Info
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String appName = 'Moweton';
}

