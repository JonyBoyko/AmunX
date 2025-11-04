import React, { useState } from 'react';
import { Alert, Button, SafeAreaView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useMutation } from '@tanstack/react-query';

import { requestMagicLink, verifyMagicLink } from '@api/auth';
import { useSession } from '@store/session';

const AuthScreen: React.FC = () => {
  const { setToken } = useSession();
  const [email, setEmail] = useState('');
  const [magicToken, setMagicToken] = useState('');

  const requestMutation = useMutation({
    mutationFn: requestMagicLink,
    onSuccess: () => {
      Alert.alert('Magic link requested', 'Check your email for the verification link.');
    },
    onError: (error: Error) => {
      Alert.alert('Error', error.message);
    }
  });

  const verifyMutation = useMutation({
    mutationFn: verifyMagicLink,
    onSuccess: (data) => {
      setToken(data.token);
    },
    onError: (error: Error) => {
      Alert.alert('Verification failed', error.message);
    }
  });

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.title}>Sign in with magic link</Text>
        <TextInput
          style={styles.input}
          placeholder="Email"
          autoCapitalize="none"
          keyboardType="email-address"
          value={email}
          onChangeText={setEmail}
        />
        <Button title="Send Link" onPress={() => requestMutation.mutate(email)} disabled={requestMutation.isPending} />

        <View style={styles.divider} />

        <Text style={styles.subtitle}>Paste token to simulate verification</Text>
        <TextInput
          style={styles.input}
          placeholder="Magic link token"
          autoCapitalize="none"
          value={magicToken}
          onChangeText={setMagicToken}
        />
        <Button
          title="Verify Token"
          onPress={() => verifyMutation.mutate(magicToken)}
          disabled={verifyMutation.isPending}
        />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: '#0f172a',
    justifyContent: 'center'
  },
  card: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 24,
    gap: 16
  },
  title: {
    fontSize: 24,
    color: '#f8fafc',
    fontWeight: '600'
  },
  subtitle: {
    fontSize: 14,
    color: '#cbd5f5'
  },
  input: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#475569',
    padding: 12,
    color: '#f8fafc'
  },
  divider: {
    height: 1,
    backgroundColor: '#334155'
  }
});

export default AuthScreen;

