const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Fix for web - exclude problematic node_modules from transformation
config.resolver = {
  ...config.resolver,
  sourceExts: [...config.resolver.sourceExts, 'cjs'],
  assetExts: [...config.resolver.assetExts.filter(ext => ext !== 'svg'), 'db'],
};

// Ignore @expo/vector-icons JSX parsing issues on web
config.transformer = {
  ...config.transformer,
  minifierPath: require.resolve('metro-minify-terser'),
  minifierConfig: {
    compress: {
      drop_console: false,
    },
  },
};

module.exports = config;
