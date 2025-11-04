import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'AmunX',
  slug: 'amunx',
  version: '0.1.0',
  scheme: 'amunx',
  ios: {
    supportsTablet: true,
    bundleIdentifier: 'com.amunx.mobile'
  },
  android: {
    package: 'com.amunx.mobile'
  },
  plugins: ['@livekit/react-native-expo-plugin', '@config-plugins/react-native-webrtc']
});
