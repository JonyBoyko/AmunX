const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

module.exports = mergeConfig(defaultConfig, {
  transformer: {
    experimentalImportSupport: false,
    inlineRequires: true
  },
  resolver: {
    sourceExts: ['tsx', 'ts', 'jsx', 'js', 'json']
  }
});

