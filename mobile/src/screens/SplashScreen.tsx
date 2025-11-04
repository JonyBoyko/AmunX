import React from 'react';
import { ActivityIndicator, SafeAreaView, StyleSheet } from 'react-native';

const SplashScreen: React.FC = () => (
  <SafeAreaView style={styles.container}>
    <ActivityIndicator size="large" />
  </SafeAreaView>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center'
  }
});

export default SplashScreen;

