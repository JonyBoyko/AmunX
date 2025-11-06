import { AppRegistry, Platform } from 'react-native';

import App from './src/App';

AppRegistry.registerComponent('AmunX', () => App);

// For web
if (Platform.OS === 'web') {
  const rootTag = document.getElementById('root') || document.getElementById('main');
  if (rootTag) {
    AppRegistry.runApplication('AmunX', { rootTag });
  }
}

