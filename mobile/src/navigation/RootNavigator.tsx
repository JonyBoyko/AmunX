import React, { useEffect } from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import SplashScreen from '@screens/SplashScreen';
import AuthScreen from '@screens/AuthScreen';
import HomeScreen from '@screens/HomeScreen';
import RecorderScreen from '@screens/RecorderScreen';
import LiveHostScreen from '@screens/LiveHostScreen';
import LiveListenerScreen from '@screens/LiveListenerScreen';

import { useSession } from '@store/session';

export type RootStackParamList = {
  Splash: undefined;
  Auth: undefined;
  Home: undefined;
  Recorder: undefined;
  Episode: { id: string };
  LiveHost: undefined;
  LiveListener: undefined;
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
          <Stack.Screen name="Home" component={HomeScreen} />
          <Stack.Screen name="Recorder" component={RecorderScreen} />
          <Stack.Screen name="Episode" component={require('@screens/EpisodeScreen').default} />
          <Stack.Screen name="LiveHost" component={LiveHostScreen} />
          <Stack.Screen name="LiveListener" component={LiveListenerScreen} />
        </>
      ) : (
        <>
          <Stack.Screen name="Auth" component={AuthScreen} />
          <Stack.Screen name="Recorder" component={RecorderScreen} />
          <Stack.Screen name="LiveListener" component={LiveListenerScreen} />
        </>
      )}
    </Stack.Navigator>
  );
};

export default RootNavigator;
