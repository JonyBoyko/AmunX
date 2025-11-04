import React, { useEffect } from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import SplashScreen from '@screens/SplashScreen';
import OnboardingScreen from '@screens/OnboardingScreen';
import AuthScreen from '@screens/AuthScreen';
import FeedScreen from '@screens/FeedScreen';
import RecorderScreen from '@screens/RecorderScreen';
import EpisodeDetailScreen from '@screens/EpisodeDetailScreen';
import CommentsScreen from '@screens/CommentsScreen';
import ProfileScreen from '@screens/ProfileScreen';
import TopicsScreen from '@screens/TopicsScreen';
import TopicDetailScreen from '@screens/TopicDetailScreen';
import LiveHostScreen from '@screens/LiveHostScreen';
import LiveListenerScreen from '@screens/LiveListenerScreen';
import PaywallScreen from '@screens/PaywallScreen';
import SettingsScreen from '@screens/SettingsScreen';

import { useSession } from '@store/session';

export type RootStackParamList = {
  Splash: undefined;
  Onboarding: undefined;
  Auth: undefined;
  Home: undefined;
  Feed: undefined;
  Recorder: undefined;
  Episode: { id: string };
  Comments: { episodeId: string; episodeTitle?: string };
  Profile: undefined;
  Topics: undefined;
  TopicDetail: { topicId: string };
  LiveHost: undefined;
  LiveListener: undefined;
  Paywall: undefined;
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

const RootNavigator: React.FC = () => {
  const { isLoading, isAuthenticated, hydrate } = useSession();

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {isLoading ? (
        <Stack.Screen name="Splash" component={SplashScreen} />
      ) : isAuthenticated ? (
        <>
          <Stack.Screen name="Feed" component={FeedScreen} />
          <Stack.Screen name="Recorder" component={RecorderScreen} />
          <Stack.Screen name="Episode" component={EpisodeDetailScreen} />
          <Stack.Screen name="Comments" component={CommentsScreen} />
          <Stack.Screen name="Profile" component={ProfileScreen} />
          <Stack.Screen name="Topics" component={TopicsScreen} />
          <Stack.Screen name="TopicDetail" component={TopicDetailScreen} />
          <Stack.Screen name="LiveHost" component={LiveHostScreen} />
          <Stack.Screen name="LiveListener" component={LiveListenerScreen} />
          <Stack.Screen name="Paywall" component={PaywallScreen} />
          <Stack.Screen name="Settings" component={SettingsScreen} />
        </>
      ) : (
        <>
          <Stack.Screen name="Onboarding" component={OnboardingScreen} />
          <Stack.Screen name="Auth" component={AuthScreen} />
          <Stack.Screen name="Recorder" component={RecorderScreen} />
          <Stack.Screen name="LiveListener" component={LiveListenerScreen} />
        </>
      )}
    </Stack.Navigator>
  );
};

export default RootNavigator;
