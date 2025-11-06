import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { VisibilitySelector } from '../components/VisibilitySelector';
import { CircleSelector } from '../components/CircleSelector';
import { theme } from '../theme/theme';
import { audioAPI } from '../api/audio';
import { uploadsAPI } from '../api/uploads';

interface CreateAudioScreenProps {
  navigation: any;
  route: {
    params: {
      recordingUri: string;
      durationSec: number;
    };
  };
}

export const CreateAudioScreen: React.FC<CreateAudioScreenProps> = ({
  navigation,
  route,
}) => {
  const { recordingUri, durationSec } = route.params;

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [tags, setTags] = useState('');
  const [visibility, setVisibility] = useState<'private' | 'circles' | 'public'>('private');
  const [selectedCircleIds, setSelectedCircleIds] = useState<string[]>([]);
  const [showCircleSelector, setShowCircleSelector] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  // Mock circles data - in real app, fetch from API
  const userCircles = [
    { id: '1', name: 'Tech Talks', description: 'Tech discussions', member_count: 42 },
    { id: '2', name: 'Startup Founders', description: 'Startup community', member_count: 128 },
  ];

  const handleToggleCircle = (circleId: string) => {
    setSelectedCircleIds((prev) =>
      prev.includes(circleId)
        ? prev.filter((id) => id !== circleId)
        : [...prev, circleId]
    );
  };

  const handlePublish = async () => {
    setIsUploading(true);
    try {
      // 1. Get presigned URL
      const presigned = await uploadsAPI.getPresignedUrl({
        mime: 'audio/mp4',
        filename: 'recording.m4a',
      });

      // 2. Upload file to S3
      const formData = new FormData();
      Object.entries(presigned.fields).forEach(([key, value]) => {
        formData.append(key, value);
      });
      formData.append('file', {
        uri: recordingUri,
        type: 'audio/mp4',
        name: 'recording.m4a',
      } as any);

      await fetch(presigned.url, {
        method: 'POST',
        body: formData,
      });

      // 3. Create audio item
      const tagArray = tags
        .split(',')
        .map((t) => t.trim())
        .filter((t) => t.length > 0);

      await audioAPI.createAudioItem({
        s3_key: presigned.s3_key,
        duration_sec: durationSec,
        kind: durationSec > 120 ? 'podcast_episode' : 'micro',
        title,
        description,
        tags: tagArray,
        visibility,
        share_to_circle_ids: visibility === 'circles' ? selectedCircleIds : [],
      });

      // Success - navigate back
      navigation.navigate('Home');
    } catch (error) {
      console.error('Upload failed:', error);
      alert('Upload failed. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.sectionTitle}>Audio Details</Text>

        <TextInput
          style={styles.input}
          placeholder="Title (optional)"
          placeholderTextColor={theme.colors.text.tertiary}
          value={title}
          onChangeText={setTitle}
        />

        <TextInput
          style={[styles.input, styles.textArea]}
          placeholder="Description (optional)"
          placeholderTextColor={theme.colors.text.tertiary}
          value={description}
          onChangeText={setDescription}
          multiline
          numberOfLines={4}
        />

        <TextInput
          style={styles.input}
          placeholder="Tags (comma-separated, e.g., tech, startup)"
          placeholderTextColor={theme.colors.text.tertiary}
          value={tags}
          onChangeText={setTags}
        />

        <Text style={styles.sectionTitle}>Privacy</Text>
        <VisibilitySelector
          value={visibility}
          onChange={setVisibility}
          onSelectCircles={() => setShowCircleSelector(true)}
        />

        {visibility === 'circles' && selectedCircleIds.length > 0 && (
          <View style={styles.selectedCircles}>
            <Text style={styles.selectedCirclesLabel}>
              Sharing to {selectedCircleIds.length} circle(s)
            </Text>
          </View>
        )}

        <TouchableOpacity
          style={[styles.publishButton, isUploading && styles.publishButtonDisabled]}
          onPress={handlePublish}
          disabled={isUploading}
        >
          {isUploading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.publishButtonText}>
              {visibility === 'private' ? 'Save Private' : 'Publish'}
            </Text>
          )}
        </TouchableOpacity>
      </ScrollView>

      <CircleSelector
        visible={showCircleSelector}
        circles={userCircles}
        selectedCircleIds={selectedCircleIds}
        onToggleCircle={handleToggleCircle}
        onClose={() => setShowCircleSelector(false)}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  content: {
    padding: theme.spacing.md,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
    marginTop: theme.spacing.lg,
  },
  input: {
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    fontSize: 16,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
    borderWidth: 1,
    borderColor: theme.colors.border.light,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  selectedCircles: {
    padding: theme.spacing.sm,
    backgroundColor: theme.colors.brand.primaryLight,
    borderRadius: theme.borderRadius.sm,
    marginTop: theme.spacing.sm,
  },
  selectedCirclesLabel: {
    fontSize: 14,
    color: theme.colors.brand.primary,
    fontWeight: '500',
  },
  publishButton: {
    backgroundColor: theme.colors.brand.primary,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    alignItems: 'center',
    marginTop: theme.spacing.xl,
    marginBottom: theme.spacing.xl,
  },
  publishButtonDisabled: {
    opacity: 0.5,
  },
  publishButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
});

