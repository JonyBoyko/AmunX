import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import RootNavigator from './navigation/RootNavigator';
import { SessionProvider } from './store/session';
import { initAnalytics } from './lib/analytics';

const queryClient = new QueryClient();
initAnalytics();

const App: React.FC = () => {
  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>
      </QueryClientProvider>
    </SessionProvider>
  );
};

export default App;
