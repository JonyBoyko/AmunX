module.exports = {
  presets: ['module:metro-react-native-babel-preset'],
  plugins: [
    [
      'module-resolver',
      {
        root: ['./src'],
        alias: {
          '@screens': './src/screens',
          '@components': './src/components',
          '@navigation': './src/navigation',
          '@store': './src/store',
          '@api': './src/api',
          '@hooks': './src/hooks'
        }
      }
    ]
  ]
};

