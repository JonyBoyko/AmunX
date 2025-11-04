import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Alert, Button, SafeAreaView, StyleSheet, Text, View } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { createEpisode, finalizeEpisode, undoEpisode } from '@api/episodes';
import type { EpisodeMask, EpisodeQuality, EpisodeVisibility } from '@api/episodes';
import { useSession } from '@store/session';

const UNDO_WINDOW_SECONDS = 10;
const MASK_OPTIONS: EpisodeMask[] = ['none', 'basic', 'studio'];
const QUALITY_OPTIONS: EpisodeQuality[] = ['raw', 'clean'];
const VISIBILITY_OPTIONS: EpisodeVisibility[] = ['public', 'anon'];

const RecorderScreen: React.FC = () => {
  const { token } = useSession();

  const [isRecording, setIsRecording] = useState(false);
  const [status, setStatus] = useState<'idle' | 'recording' | 'uploading' | 'undo' | 'completed'>('idle');
  const [visibility, setVisibility] = useState<EpisodeVisibility>('public');
  const [quality, setQuality] = useState<EpisodeQuality>('clean');
  const [mask, setMask] = useState<EpisodeMask>('none');
  const [durationSec, setDurationSec] = useState(0);
  const [noiseLevel, setNoiseLevel] = useState(0);
  const [undoRemaining, setUndoRemaining] = useState(0);
  const [episodeId, setEpisodeId] = useState<string | null>(null);
  const [publicReminderCount, setPublicReminderCount] = useState(0);

  const durationTimerRef = useRef<NodeJS.Timeout | null>(null);
  const noiseTimerRef = useRef<NodeJS.Timeout | null>(null);
  const undoTimerRef = useRef<NodeJS.Timeout | null>(null);

  const recordingDisabled = status === 'uploading';
  const showPublicReminder = publicReminderCount < 3;

  useEffect(() => {
    (async () => {
      try {
        const stored = await AsyncStorage.getItem('publicReminderCount');
        if (stored) {
          const parsed = parseInt(stored, 10);
          if (!Number.isNaN(parsed)) {
            setPublicReminderCount(parsed);
          }
        }
      } catch {
        // ignore hydration issues
      }
    })();
    return () => {
      if (durationTimerRef.current) clearInterval(durationTimerRef.current);
      if (noiseTimerRef.current) clearInterval(noiseTimerRef.current);
      if (undoTimerRef.current) clearInterval(undoTimerRef.current);
    };
  }, []);

  const clearRecordingTimers = useCallback(() => {
    if (durationTimerRef.current) {
      clearInterval(durationTimerRef.current);
      durationTimerRef.current = null;
    }
    if (noiseTimerRef.current) {
      clearInterval(noiseTimerRef.current);
      noiseTimerRef.current = null;
    }
  }, []);

  const clearUndoTimer = useCallback(() => {
    if (undoTimerRef.current) {
      clearInterval(undoTimerRef.current);
      undoTimerRef.current = null;
    }
    setUndoRemaining(0);
    setEpisodeId(null);
  }, []);

  const reset = useCallback(() => {
    clearRecordingTimers();
    clearUndoTimer();
    setDurationSec(0);
    setNoiseLevel(0);
    setStatus('idle');
    setIsRecording(false);
  }, [clearRecordingTimers, clearUndoTimer]);

  const startRecording = useCallback(() => {
    setStatus('recording');
    setIsRecording(true);
    setDurationSec(0);
    setNoiseLevel(0);

    durationTimerRef.current = setInterval(() => {
      setDurationSec((prev) => prev + 1);
    }, 1000);

    noiseTimerRef.current = setInterval(() => {
      setNoiseLevel(Math.floor(Math.random() * 60) + 20);
    }, 700);
  }, []);

  const startUndoTimer = useCallback(() => {
    clearUndoTimer();
    setStatus('undo');
    setUndoRemaining(UNDO_WINDOW_SECONDS);

    undoTimerRef.current = setInterval(() => {
      setUndoRemaining((prev) => {
        if (prev <= 1) {
          clearUndoTimer();
          setStatus('completed');
          Alert.alert('Published', 'Episode is now public.');
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  }, [clearUndoTimer]);

  const processRecording = useCallback(async () => {
    if (!token) {
      Alert.alert('Sign in required', 'Please sign in to publish voice notes.');
      return;
    }

    setStatus('uploading');

    const safeDuration = Math.max(durationSec, 1);

    try {
      const response = await createEpisode({
        token,
        visibility,
        mask,
        quality,
        durationSec: safeDuration
      });

      const audioPayload = new Uint8Array(Math.max(1, safeDuration * 500)).fill(128);
      const uploadHeaders: Record<string, string> = {};
      if (response.upload_headers) {
        Object.entries(response.upload_headers).forEach(([key, value]) => {
          uploadHeaders[key] = value;
        });
      }
      if (!uploadHeaders['Content-Type']) {
        uploadHeaders['Content-Type'] = 'audio/webm';
      }

      const uploadResult = await fetch(response.upload_url, {
        method: 'PUT',
        headers: uploadHeaders,
        body: audioPayload
      });

      if (!uploadResult.ok) {
        const text = await uploadResult.text();
        throw new Error(text || 'Upload failed');
      }

      await finalizeEpisode(token, response.id);
      setEpisodeId(response.id);
      setPublicReminderCount((prev) => {
        const next = prev + 1;
        AsyncStorage.setItem('publicReminderCount', String(next)).catch(() => {});
        return next;
      });
      startUndoTimer();
      Alert.alert('Uploaded', 'Episode is queued. You can undo within 10 seconds.');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unexpected error';
      Alert.alert('Error', message);
      reset();
    }
  }, [durationSec, mask, quality, reset, startUndoTimer, token, visibility]);

  const handleRecordToggle = useCallback(async () => {
    if (!token) {
      Alert.alert('Sign in required', 'Please sign in to record.');
      return;
    }

    if (isRecording) {
      clearRecordingTimers();
      setIsRecording(false);
      await processRecording();
    } else if (!recordingDisabled) {
      startRecording();
    }
  }, [clearRecordingTimers, isRecording, processRecording, recordingDisabled, startRecording, token]);

  const handleUndo = useCallback(async () => {
    if (!token || !episodeId) {
      return;
    }

    try {
      await undoEpisode(token, episodeId);
      Alert.alert('Undo', 'Episode has been cancelled.');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Undo failed';
      Alert.alert('Undo failed', message);
    } finally {
      clearUndoTimer();
      reset();
    }
  }, [clearUndoTimer, episodeId, reset, token]);

  const noiseText = useMemo(() => {
    if (!isRecording) return '�';
    return `${noiseLevel} dB`;
  }, [isRecording, noiseLevel]);

  const timerText = useMemo(() => {
    const minutes = Math.floor(durationSec / 60)
      .toString()
      .padStart(2, '0');
    const seconds = (durationSec % 60)
      .toString()
      .padStart(2, '0');
    return `${minutes}:${seconds}`;
  }, [durationSec]);

  return (
    <SafeAreaView style={styles.container}>
      {showPublicReminder && (
        <View style={styles.reminder}>
          <Text style={styles.reminderText}>Heads up: posts are public by default. You can undo within 10 seconds.</Text>
        </View>
      )}
      <View style={styles.stateCard}>
        <Text style={styles.sectionTitle}>Visibility</Text>
        <View style={styles.row}>
          {VISIBILITY_OPTIONS.map((option) => (
            <Button
              key={option}
              title={option === 'public' ? 'Public' : 'Anon'}
              onPress={() => setVisibility(option)}
              color={visibility === option ? '#22c55e' : undefined}
              disabled={isRecording || recordingDisabled || status === 'undo'}
            />
          ))}
        </View>

        <Text style={styles.sectionTitle}>Quality</Text>
        <View style={styles.row}>
          {QUALITY_OPTIONS.map((option) => (
            <Button
              key={option}
              title={option.toUpperCase()}
              onPress={() => setQuality(option)}
              color={quality === option ? '#f97316' : undefined}
              disabled={isRecording || recordingDisabled || status === 'undo'}
            />
          ))}
        </View>

        <Text style={styles.sectionTitle}>Mask</Text>
        <View style={styles.row}>
          {MASK_OPTIONS.map((option) => (
            <Button
              key={option}
              title={option.charAt(0).toUpperCase() + option.slice(1)}
              onPress={() => setMask(option)}
              color={mask === option ? '#38bdf8' : undefined}
              disabled={isRecording || recordingDisabled || status === 'undo'}
            />
          ))}
        </View>
      </View>

      <View style={styles.recorderCard}>
        <Text style={styles.timer}>{timerText}</Text>
        <Text style={styles.statusText}>{status.toUpperCase()}</Text>
        <Text style={styles.noiseText}>Noise level: {noiseText}</Text>
        <Button
          title={isRecording ? 'Stop' : status === 'uploading' ? 'Uploading...' : 'Record'}
          onPress={handleRecordToggle}
          color={isRecording ? '#ef4444' : '#22c55e'}
          disabled={recordingDisabled && !isRecording}
        />
        {status === 'undo' && (
          <>
            <Text style={styles.undoText}>Publishing in {undoRemaining}s</Text>
            <Button title="Undo" onPress={handleUndo} color="#facc15" />
          </>
        )}
        {status === 'completed' && (
          <Button title="Record again" onPress={reset} />
        )}
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
  reminder: {
    backgroundColor: '#1f2937',
    borderRadius: 12,
    padding: 12
  },
  reminderText: {
    color: '#facc15',
    fontSize: 14
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
    gap: 12
  },
  sectionTitle: {
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
    fontSize: 32,
    fontWeight: '700'
  },
  statusText: {
    color: '#93c5fd',
    fontSize: 16,
    marginBottom: 4
  },
  noiseText: {
    color: '#f8fafc',
    marginBottom: 12
  },
  undoText: {
    color: '#facc15',
    fontWeight: '600'
  }
});

export default RecorderScreen;
