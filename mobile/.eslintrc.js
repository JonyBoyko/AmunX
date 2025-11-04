module.exports = {
  root: true,
  extends: ['@react-native', 'plugin:@tanstack/eslint-plugin-query/recommended'],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }]
  }
};

