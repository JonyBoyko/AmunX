import React from 'react';
import { Button, SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

import { useSession } from '@store/session';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@navigation/RootNavigator';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

const HomeScreen: React.FC<Props> = ({ navigation }) => {
  const { setToken } = useSession();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.heading}>AmunX Feed</Text>
        <Button title="Record" onPress={() => navigation.navigate('Recorder')} />
      </View>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.placeholder}>Feed is coming soon. Publish your first voice note!</Text>
      </ScrollView>
      <Button title="Sign out" onPress={() => setToken(null)} />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0f172a',
    padding: 16,
    gap: 16
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  heading: {
    color: '#f8fafc',
    fontSize: 22,
    fontWeight: '600'
  },
  content: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center'
  },
  placeholder: {
    color: '#94a3b8',
    fontSize: 16,
    textAlign: 'center'
  }
});

export default HomeScreen;

