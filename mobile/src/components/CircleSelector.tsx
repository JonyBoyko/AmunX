import React from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Modal,
} from 'react-native';
import { theme } from '../theme/theme';

interface Circle {
  id: string;
  name: string;
  description: string;
  member_count: number;
}

interface CircleSelectorProps {
  visible: boolean;
  circles: Circle[];
  selectedCircleIds: string[];
  onToggleCircle: (circleId: string) => void;
  onClose: () => void;
}

export const CircleSelector: React.FC<CircleSelectorProps> = ({
  visible,
  circles,
  selectedCircleIds,
  onToggleCircle,
  onClose,
}) => {
  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Select Circles</Text>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.doneButton}>Done</Text>
          </TouchableOpacity>
        </View>

        <FlatList
          data={circles}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => {
            const isSelected = selectedCircleIds.includes(item.id);
            return (
              <TouchableOpacity
                style={[styles.circleItem, isSelected && styles.circleItemSelected]}
                onPress={() => onToggleCircle(item.id)}
              >
                <View style={styles.circleContent}>
                  <Text style={[styles.circleName, isSelected && styles.textSelected]}>
                    {item.name}
                  </Text>
                  <Text style={styles.circleDesc}>
                    {item.member_count} members
                  </Text>
                </View>
                {isSelected && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>
            );
          }}
          contentContainerStyle={styles.listContent}
        />
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
  doneButton: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.brand.primary,
  },
  listContent: {
    padding: theme.spacing.md,
  },
  circleItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background.secondary,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  circleItemSelected: {
    borderColor: theme.colors.brand.primary,
    backgroundColor: theme.colors.brand.primaryLight,
  },
  circleContent: {
    flex: 1,
  },
  circleName: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: 2,
  },
  circleDesc: {
    fontSize: 13,
    color: theme.colors.text.tertiary,
  },
  textSelected: {
    color: theme.colors.brand.primary,
  },
  checkmark: {
    fontSize: 20,
    color: theme.colors.brand.primary,
    fontWeight: 'bold',
  },
});

