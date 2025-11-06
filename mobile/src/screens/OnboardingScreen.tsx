import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { theme } from '../theme/theme';

const { width } = Dimensions.get('window');

const TOPICS = [
  'Founders',
  'Self-Improvement',
  'Tech & Coding',
  'Finance',
  'College Life',
  'Fitness',
  'News & Takes',
  'Language Learning',
  'Design',
  'Productivity',
];

interface OnboardingScreenProps {
  navigation: any;
}

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({
  navigation,
}) => {
  const [step, setStep] = useState(0);
  const [selectedTopics, setSelectedTopics] = useState<string[]>([]);
  const [agreedPrivacy, setAgreedPrivacy] = useState(false);

  const handleTopicToggle = (topic: string) => {
    setSelectedTopics(prev =>
      prev.includes(topic)
        ? prev.filter(t => t !== topic)
        : [...prev, topic]
    );
  };

  const handleNext = () => {
    if (step === 0) {
      setStep(1); // Topics
    } else if (step === 1 && selectedTopics.length >= 3) {
      setStep(2); // Privacy
    } else if (step === 2 && agreedPrivacy) {
      setStep(3); // Notifications
    }
  };

  const handleFinish = () => {
    // Save onboarding state
    navigation.replace('Home');
  };

  // Step 0: Welcome
  if (step === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.content}>
          <Text style={styles.title}>Speak your mind.{'\n'}We'll do the rest.</Text>
          
          <View style={styles.bullets}>
            <Text style={styles.bullet}>✓ Private by default</Text>
            <Text style={styles.bullet}>✓ 60–120s notes</Text>
            <Text style={styles.bullet}>✓ One-tap sharing</Text>
          </View>

          <Text style={styles.subtitle}>
            Your voice notes, auto-transcribed with smart clips.
            Share to Explore or keep them private.
          </Text>
        </View>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.button} onPress={handleNext}>
            <Text style={styles.buttonText}>Continue with Apple</Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.button, styles.buttonSecondary]}
            onPress={handleNext}
          >
            <Text style={[styles.buttonText, styles.buttonTextSecondary]}>
              Continue with Google
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // Step 1: Topics
  if (step === 1) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Pick your topics</Text>
          <Text style={styles.headerSubtitle}>
            Select 3+ topics to personalize your feed
          </Text>
        </View>

        <ScrollView contentContainerStyle={styles.topicsContainer}>
          {TOPICS.map(topic => (
            <TouchableOpacity
              key={topic}
              style={[
                styles.topicChip,
                selectedTopics.includes(topic) && styles.topicChipSelected,
              ]}
              onPress={() => handleTopicToggle(topic)}
            >
              <Text
                style={[
                  styles.topicText,
                  selectedTopics.includes(topic) && styles.topicTextSelected,
                ]}
              >
                {topic}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.button, selectedTopics.length < 3 && styles.buttonDisabled]}
            onPress={handleNext}
            disabled={selectedTopics.length < 3}
          >
            <Text style={styles.buttonText}>
              Next ({selectedTopics.length}/3)
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // Step 2: Privacy
  if (step === 2) {
    return (
      <View style={styles.container}>
        <View style={styles.content}>
          <Text style={styles.icon}>🔒</Text>
          <Text style={styles.title}>Your recordings are private</Text>
          
          <Text style={styles.privacyText}>
            Everything you record is{' '}
            <Text style={styles.privacyHighlight}>private</Text> unless you
            share it to Explore or a Circle.
          </Text>

          <TouchableOpacity
            style={styles.checkbox}
            onPress={() => setAgreedPrivacy(!agreedPrivacy)}
          >
            <View
              style={[
                styles.checkboxBox,
                agreedPrivacy && styles.checkboxBoxChecked,
              ]}
            >
              {agreedPrivacy && <Text style={styles.checkmark}>✓</Text>}
            </View>
            <Text style={styles.checkboxLabel}>
              I understand my recordings stay private until I share them
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.button, !agreedPrivacy && styles.buttonDisabled]}
            onPress={handleNext}
            disabled={!agreedPrivacy}
          >
            <Text style={styles.buttonText}>Continue</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // Step 3: Notifications
  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.icon}>🔔</Text>
        <Text style={styles.title}>Enable notifications</Text>
        
        <Text style={styles.privacyText}>
          Get gentle prompts and replies from your Circles.
          You can always change this later.
        </Text>
      </View>

      <View style={styles.footer}>
        <TouchableOpacity style={styles.button} onPress={handleFinish}>
          <Text style={styles.buttonText}>Enable</Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={styles.buttonLink}
          onPress={handleFinish}
        >
          <Text style={styles.buttonLinkText}>Not now</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background.primary,
  },
  header: {
    padding: theme.spacing.lg,
    paddingTop: theme.spacing.xl * 2,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  headerSubtitle: {
    fontSize: 16,
    color: theme.colors.text.secondary,
  },
  content: {
    flex: 1,
    padding: theme.spacing.xl,
    justifyContent: 'center',
    alignItems: 'center',
  },
  icon: {
    fontSize: 64,
    marginBottom: theme.spacing.xl,
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
  },
  subtitle: {
    fontSize: 18,
    lineHeight: 28,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  bullets: {
    alignSelf: 'stretch',
    marginVertical: theme.spacing.xl,
  },
  bullet: {
    fontSize: 18,
    lineHeight: 32,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  privacyText: {
    fontSize: 18,
    lineHeight: 28,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.xl,
  },
  privacyHighlight: {
    color: theme.colors.brand.primary,
    fontWeight: '700',
  },
  checkbox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    padding: theme.spacing.md,
  },
  checkboxBox: {
    width: 24,
    height: 24,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: theme.colors.border.light,
    marginRight: theme.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxBoxChecked: {
    backgroundColor: theme.colors.brand.primary,
    borderColor: theme.colors.brand.primary,
  },
  checkmark: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
  checkboxLabel: {
    flex: 1,
    fontSize: 16,
    lineHeight: 24,
    color: theme.colors.text.primary,
  },
  topicsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: theme.spacing.lg,
    gap: theme.spacing.sm,
  },
  topicChip: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.full,
    borderWidth: 2,
    borderColor: theme.colors.border.light,
  },
  topicChipSelected: {
    backgroundColor: theme.colors.brand.primary,
    borderColor: theme.colors.brand.primary,
  },
  topicText: {
    fontSize: 16,
    fontWeight: '500',
    color: theme.colors.text.primary,
  },
  topicTextSelected: {
    color: '#fff',
  },
  footer: {
    padding: theme.spacing.lg,
  },
  button: {
    backgroundColor: theme.colors.brand.primary,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  buttonSecondary: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: theme.colors.border.light,
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  buttonTextSecondary: {
    color: theme.colors.text.primary,
  },
  buttonLink: {
    padding: theme.spacing.sm,
    alignItems: 'center',
  },
  buttonLinkText: {
    fontSize: 16,
    color: theme.colors.text.tertiary,
  },
});
