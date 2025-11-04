import * as Sentry from '@sentry/react-native';
import PostHog, { PostHogOptions, PostHogEventProperties } from 'posthog-react-native';
import Config from 'react-native-config';

let posthogClient: PostHog | null = null;

export function initAnalytics() {
  if (Config.SENTRY_DSN) {
    Sentry.init({
      dsn: Config.SENTRY_DSN,
      tracesSampleRate: 0.1
    });
  }

  if (Config.POSTHOG_API_KEY) {
    const options: PostHogOptions = {
      host: Config.POSTHOG_HOST ?? 'https://app.posthog.com'
    };
    posthogClient = new PostHog(Config.POSTHOG_API_KEY, options);
  }
}

export function track(event: string, properties?: PostHogEventProperties) {
  if (!posthogClient) {
    return;
  }
  posthogClient.capture(event, properties);
}
