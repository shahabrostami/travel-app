/**
 * Jest configuration for integration tests
 * Does NOT mock Supabase - uses real database connection
 */
module.exports = {
  preset: 'jest-expo',
  testMatch: ['**/__tests__/integration/**/*.test.[jt]s?(x)'],
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)',
  ],
  // Use a minimal setup that doesn't mock Supabase
  setupFilesAfterEnv: ['<rootDir>/jest.integration.setup.js'],
  testEnvironment: 'node',
  // Longer timeout for database operations
  testTimeout: 30000,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
};
