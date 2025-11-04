import React, { useState } from 'react';
import { Alert, Button, SafeAreaView, StyleSheet, Text, View } from 'react-native';

const RecorderScreen: React.FC = () => {
  const [isRecording, setIsRecording] = useState(false);
  const [quality, setQuality] = useState<'raw' | 'clean'>('clean');
  const [visibility, setVisibility] = useState<'public' | 'anon'>('public');
  const [mask, setMask] = useState<'none' | 'basic'>('none');

  const toggleRecording = () => {
    setIsRecording((prev) => !prev);
  };

  const handleUpload = () => {
    Alert.alert('Upload queued', 'Audio processing pipeline will handle it.');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.stateCard}>
        <Text style={styles.label}>Visibility</Text>
        <View style={styles.row}>
          <Button title="Public" onPress={() => setVisibility('public')} color={visibility === 'public' ? '#22c55e' : undefined} />
          <Button title="Anon" onPress={() => setVisibility('anon')} color={visibility === 'anon' ? '#22c55e' : undefined} />
        </View>
        <Text style={styles.label}>Quality</Text>
        <View style={styles.row}>
          <Button title="Raw" onPress={() => setQuality('raw')} color={quality === 'raw' ? '#f97316' : undefined} />
          <Button title="Clean" onPress={() => setQuality('clean')} color={quality === 'clean' ? '#f97316' : undefined} />
        </View>
        <Text style={styles.label}>Mask</Text>
        <View style={styles.row}>
          <Button title="None" onPress={() => setMask('none')} color={mask === 'none' ? '#38bdf8' : undefined} />
          <Button title="Basic" onPress={() => setMask('basic')} color={mask === 'basic' ? '#38bdf8' : undefined} />
        </View>
      </View>

      <View style={styles.recorderCard}>
        <Text style={styles.timer}>{isRecording ? 'Recording...' : 'Tap to record'}</Text>
        <Button title={isRecording ? 'Stop' : 'Record'} onPress={toggleRecording} color={isRecording ? '#ef4444' : '#22c55e'} />
        <Button title="Upload" onPress={handleUpload} disabled={isRecording} />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    gap: 16,
    padding: 16,
    backgroundColor: '#0f172a'
  },
  stateCard: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 16,
    gap: 12
  },
  recorderCard: {
    flex: 1,
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16
  },
  label: {
    color: '#cbd5f5',
    fontSize: 14,
    fontWeight: '600'
  },
  row: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'space-around'
  },
  timer: {
    color: '#f8fafc',
    fontSize: 20,
    fontWeight: '600'
  }
});

export default RecorderScreen;

