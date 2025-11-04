module.exports = {
  presets: ['babel-preset-expo'],
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
