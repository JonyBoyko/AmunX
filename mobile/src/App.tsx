import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { View, ActivityIndicator, StyleSheet } from 'react-native';

import RootNavigator from './navigation/RootNavigator';
import { SessionProvider } from './store/session';
import { initAnalytics } from './lib/analytics';
import { initI18n } from '@i18n/index';
import { theme } from '@theme/theme';
import { usePushNotifications } from '@hooks/usePushNotifications';

const queryClient = new QueryClient();
initAnalytics();

function AppContent() {
  // Setup push notifications globally
  usePushNotifications();

  return <RootNavigator />;
}

const App: React.FC = () => {
  const [i18nReady, setI18nReady] = useState(false);

  useEffect(() => {
    const init = async () => {
      await initI18n();
      setI18nReady(true);
    };
    init();
  }, []);

  if (!i18nReady) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={theme.colors.brand.primary} />
      </View>
    );
  }

  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        <NavigationContainer>
          <AppContent />
        </NavigationContainer>
      </QueryClientProvider>
    </SessionProvider>
  );
};

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.bg.base,
  },
});

export default App;
