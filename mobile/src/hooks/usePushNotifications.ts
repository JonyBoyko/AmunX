import { useEffect, useRef } from 'react';
import * as Notifications from 'expo-notifications';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';

import {
  setupPushNotifications,
  addNotificationReceivedListener,
  addNotificationResponseListener,
} from '@services/pushNotifications';
import { useSession } from '@store/session';

/**
 * Hook to manage push notifications in the app
 */
export function usePushNotifications() {
  const { token } = useSession();
  const navigation = useNavigation<NativeStackNavigationProp<any>>();
  const notificationListener = useRef<Notifications.Subscription | null>(null);
  const responseListener = useRef<Notifications.Subscription | null>(null);

  useEffect(() => {
    // Setup push notifications when user is authenticated
    if (token) {
      setupPushNotifications(token).catch((error) => {
        console.error('Failed to setup push notifications:', error);
      });
    }

    // Listen for notifications received while app is in foreground
    notificationListener.current = addNotificationReceivedListener((notification) => {
      console.log('Notification received:', notification);
      // You can show an in-app banner here if desired
    });

    // Listen for notification taps (when user opens a notification)
    responseListener.current = addNotificationResponseListener((response) => {
      console.log('Notification tapped:', response);

      const data = response.notification.request.content.data;

      // Navigate based on notification type
      if (data.type === 'episode') {
        navigation.navigate('Episode', { id: data.episodeId });
      } else if (data.type === 'comment') {
        navigation.navigate('Comments', {
          episodeId: data.episodeId,
          episodeTitle: data.episodeTitle,
        });
      } else if (data.type === 'live') {
        navigation.navigate('LiveListener');
      } else if (data.type === 'reaction') {
        navigation.navigate('Episode', { id: data.episodeId });
      }
    });

    // Cleanup
    return () => {
      if (notificationListener.current) {
        Notifications.removeNotificationSubscription(notificationListener.current);
      }
      if (responseListener.current) {
        Notifications.removeNotificationSubscription(responseListener.current);
      }
    };
  }, [token, navigation]);
}

