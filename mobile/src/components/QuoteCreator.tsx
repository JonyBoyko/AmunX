import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Modal,
  ActivityIndicator,
} from 'react-native';
import Slider from '@react-native-community/slider';
import { theme } from '../theme/theme';
import { audioAPI } from '../api/audio';
import { recordFeedEvent } from '../api/events';

interface QuoteCreatorProps {
  visible: boolean;
  audioId: string;
  durationSec: number;
  transcript?: {
    text: string;
    words?: Array<{ word: string; start: number; end: number }>;
  };
  onClose: () => void;
  onSuccess?: (clipId: string) => void;
}

export const QuoteCreator: React.FC<QuoteCreatorProps> = ({
  visible,
  audioId,
  durationSec,
  transcript,
  onClose,
  onSuccess,
}) => {
  const [startSec, setStartSec] = useState(0);
  const [endSec, setEndSec] = useState(Math.min(15, durationSec));
  const [selectedText, setSelectedText] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  const handleCreate = async () => {
    if (endSec <= startSec) {
      alert('End time must be after start time');
      return;
    }

    if (endSec - startSec > 30) {
      alert('Clips must be 30 seconds or less');
      return;
    }

    setIsCreating(true);
    try {
      // Create clip via API
      const response = await fetch(`/audio/${audioId}/clips`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          start_sec: Math.floor(startSec),
          end_sec: Math.floor(endSec),
          quote: selectedText,
        }),
      });

      const clip = await response.json();

      // Record event
      await recordFeedEvent({
        audio_id: audioId,
        event: 'quote',
        meta: {
          start_sec: startSec,
          end_sec: endSec,
          clip_id: clip.id,
        },
      });

      onSuccess?.(clip.id);
      onClose();
    } catch (error) {
      console.error('Failed to create quote:', error);
      alert('Failed to create clip. Please try again.');
    } finally {
      setIsCreating(false);
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getTranscriptInRange = () => {
    if (!transcript?.words) return '';
    
    return transcript.words
      .filter(w => w.start >= startSec && w.end <= endSec)
      .map(w => w.word)
      .join(' ');
  };

  React.useEffect(() => {
    setSelectedText(getTranscriptInRange());
  }, [startSec, endSec]);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Create Quote Clip</Text>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.closeButton}>✕</Text>
          </TouchableOpacity>
        </View>

        <ScrollView contentContainerStyle={styles.content}>
          {/* Time Range Selector */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Select Range</Text>
            
            <View style={styles.rangeDisplay}>
              <View style={styles.timeBox}>
                <Text style={styles.timeLabel}>Start</Text>
                <Text style={styles.timeValue}>{formatTime(startSec)}</Text>
              </View>
              
              <Text style={styles.duration}>
                {Math.round(endSec - startSec)}s
              </Text>
              
              <View style={styles.timeBox}>
                <Text style={styles.timeLabel}>End</Text>
                <Text style={styles.timeValue}>{formatTime(endSec)}</Text>
              </View>
            </View>

            {/* Start Slider */}
            <View style={styles.sliderContainer}>
              <Text style={styles.sliderLabel}>Start</Text>
              <Slider
                style={styles.slider}
                minimumValue={0}
                maximumValue={durationSec}
                value={startSec}
                onValueChange={setStartSec}
                minimumTrackTintColor={theme.colors.brand.primary}
                maximumTrackTintColor={theme.colors.border.light}
              />
            </View>

            {/* End Slider */}
            <View style={styles.sliderContainer}>
              <Text style={styles.sliderLabel}>End</Text>
              <Slider
                style={styles.slider}
                minimumValue={0}
                maximumValue={durationSec}
                value={endSec}
                onValueChange={setEndSec}
                minimumTrackTintColor={theme.colors.brand.primary}
                maximumTrackTintColor={theme.colors.border.light}
              />
            </View>
          </View>

          {/* Preview Text */}
          {selectedText && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Quote Preview</Text>
              <View style={styles.quoteBox}>
                <Text style={styles.quoteText}>"{selectedText}"</Text>
              </View>
            </View>
          )}

          {/* Quick Presets */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Quick Presets</Text>
            <View style={styles.presets}>
              <TouchableOpacity
                style={styles.presetButton}
                onPress={() => {
                  setStartSec(0);
                  setEndSec(15);
                }}
              >
                <Text style={styles.presetText}>First 15s</Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={styles.presetButton}
                onPress={() => {
                  setStartSec(Math.max(0, durationSec - 15));
                  setEndSec(durationSec);
                }}
              >
                <Text style={styles.presetText}>Last 15s</Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={styles.presetButton}
                onPress={() => {
                  const mid = durationSec / 2;
                  setStartSec(Math.max(0, mid - 10));
                  setEndSec(Math.min(durationSec, mid + 10));
                }}
              >
                <Text style={styles.presetText}>Middle 20s</Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>

        {/* Create Button */}
        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.createButton, isCreating && styles.createButtonDisabled]}
            onPress={handleCreate}
            disabled={isCreating}
          >
            {isCreating ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.createButtonText}>Create Clip</Text>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border.light,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: theme.colors.text.primary,
  },
  closeButton: {
    fontSize: 24,
    color: theme.colors.text.tertiary,
  },
  content: {
    padding: theme.spacing.md,
  },
  section: {
    marginBottom: theme.spacing.xl,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  rangeDisplay: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.md,
  },
  timeBox: {
    alignItems: 'center',
  },
  timeLabel: {
    fontSize: 12,
    color: theme.colors.text.tertiary,
    marginBottom: 4,
  },
  timeValue: {
    fontSize: 18,
    fontWeight: '700',
    color: theme.colors.text.primary,
  },
  duration: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.brand.primary,
  },
  sliderContainer: {
    marginBottom: theme.spacing.md,
  },
  sliderLabel: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  quoteBox: {
    padding: theme.spacing.md,
    backgroundColor: theme.colors.brand.primaryLight,
    borderRadius: theme.borderRadius.md,
    borderLeftWidth: 4,
    borderLeftColor: theme.colors.brand.primary,
  },
  quoteText: {
    fontSize: 16,
    lineHeight: 24,
    color: theme.colors.text.primary,
    fontStyle: 'italic',
  },
  presets: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  presetButton: {
    flex: 1,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
  },
  presetText: {
    fontSize: 14,
    fontWeight: '500',
    color: theme.colors.text.primary,
  },
  footer: {
    padding: theme.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border.light,
  },
  createButton: {
    backgroundColor: theme.colors.brand.primary,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
  },
  createButtonDisabled: {
    opacity: 0.5,
  },
  createButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
});

