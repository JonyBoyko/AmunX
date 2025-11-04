import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Pressable,
  FlatList,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RouteProp } from '@react-navigation/native';
import { useTranslation } from 'react-i18next';

import { theme } from '@theme/theme';
import { applyShadow } from '@theme/utils';
import { useSession } from '@store/session';
import { listComments, postComment, type Comment } from '@api/comments';

type CommentsScreenProps = {
  navigation: NativeStackNavigationProp<any>;
  route: RouteProp<{ params: { episodeId: string; episodeTitle?: string } }, 'params'>;
};

const CommentsScreen: React.FC<CommentsScreenProps> = ({ navigation, route }) => {
  const { episodeId, episodeTitle } = route.params;
  const { token } = useSession();
  const { t } = useTranslation();

  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(true);
  const [posting, setPosting] = useState(false);
  const [commentText, setCommentText] = useState('');
  const inputRef = useRef<TextInput>(null);

  useEffect(() => {
    loadComments();
  }, [episodeId]);

  const loadComments = async () => {
    try {
      setLoading(true);
      const data = await listComments(episodeId);
      setComments(data.items);
    } catch (err: any) {
      Alert.alert(t('common.error'), err?.message || 'Failed to load comments');
    } finally {
      setLoading(false);
    }
  };

  const handlePostComment = async () => {
    if (!token) {
      Alert.alert(t('errors.unauthorized'), t('errors.unauthorized'));
      return;
    }

    if (!commentText.trim()) {
      return;
    }

    try {
      setPosting(true);
      const result = await postComment(token, episodeId, commentText.trim());

      if (result.flagged) {
        Alert.alert(
          t('comments.flagged.title', { defaultValue: 'Comment Flagged' }),
          t('comments.flagged.message', {
            defaultValue: 'Your comment has been flagged for review.',
          })
        );
      }

      setComments([result.comment, ...comments]);
      setCommentText('');
      inputRef.current?.blur();
    } catch (err: any) {
      Alert.alert(t('common.error'), err?.message || 'Failed to post comment');
    } finally {
      setPosting(false);
    }
  };

  const renderComment = ({ item }: { item: Comment }) => {
    const commentDate = new Date(item.created_at).toLocaleDateString();

    return (
      <View style={styles.commentCard}>
        <View style={styles.commentHeader}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {item.author_id.substring(0, 2).toUpperCase()}
            </Text>
          </View>
          <View style={styles.commentMeta}>
            <Text style={styles.authorText}>
              {item.is_anon ? t('comments.anonymous', { defaultValue: 'Anonymous' }) : 'User'}
            </Text>
            <Text style={styles.dateText}>{commentDate}</Text>
          </View>
          {item.is_flagged && (
            <View style={styles.flaggedBadge}>
              <Ionicons name="flag" size={12} color={theme.colors.state.warning} />
            </View>
          )}
        </View>
        <Text style={styles.commentText}>{item.text}</Text>
      </View>
    );
  };

  const renderEmpty = () => {
    if (loading) {
      return (
        <View style={styles.emptyContainer}>
          <ActivityIndicator size="large" color={theme.colors.brand.primary} />
          <Text style={styles.emptyText}>{t('common.loading')}</Text>
        </View>
      );
    }

    return (
      <View style={styles.emptyContainer}>
        <Ionicons name="chatbubbles-outline" size={64} color={theme.colors.text.secondary} />
        <Text style={styles.emptyTitle}>
          {t('comments.empty.title', { defaultValue: 'No comments yet' })}
        </Text>
        <Text style={styles.emptyText}>
          {t('comments.empty.message', { defaultValue: 'Be the first to comment!' })}
        </Text>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg.base} />

      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color={theme.colors.text.primary} />
        </Pressable>
        <View style={styles.headerTitleContainer}>
          <Text style={styles.headerTitle}>
            {t('comments.title', { defaultValue: 'Comments' })}
          </Text>
          {episodeTitle && <Text style={styles.headerSubtitle} numberOfLines={1}>{episodeTitle}</Text>}
        </View>
        <View style={{ width: 40 }} />
      </View>

      {/* Comments List */}
      <FlatList
        data={comments}
        keyExtractor={(item) => item.id}
        renderItem={renderComment}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={renderEmpty}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        showsVerticalScrollIndicator={false}
      />

      {/* Input Area */}
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
      >
        <View style={styles.inputContainer}>
          <View style={styles.inputWrapper}>
            <TextInput
              ref={inputRef}
              style={styles.input}
              placeholder={t('comments.placeholder', { defaultValue: 'Add a comment...' })}
              placeholderTextColor={theme.colors.text.secondary}
              value={commentText}
              onChangeText={setCommentText}
              multiline
              maxLength={500}
              editable={!posting}
            />
            <Pressable
              onPress={handlePostComment}
              disabled={!commentText.trim() || posting}
              style={[
                styles.sendButton,
                (!commentText.trim() || posting) && styles.sendButtonDisabled,
              ]}
            >
              {posting ? (
                <ActivityIndicator size="small" color={theme.colors.text.inverse} />
              ) : (
                <Ionicons
                  name="send"
                  size={20}
                  color={
                    commentText.trim()
                      ? theme.colors.text.inverse
                      : theme.colors.text.secondary
                  }
                />
              )}
            </Pressable>
          </View>
          <Text style={styles.charCount}>{commentText.length}/500</Text>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg.base,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.space.lg,
    paddingVertical: theme.space.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.surface.border,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitleContainer: {
    flex: 1,
    alignItems: 'center',
    gap: 2,
  },
  headerTitle: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  headerSubtitle: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
  },
  listContent: {
    padding: theme.space.lg,
    paddingBottom: theme.space.xxl,
  },
  commentCard: {
    gap: theme.space.md,
  },
  commentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.space.md,
  },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: theme.colors.text.inverse,
    fontSize: 14,
    fontWeight: '600',
  },
  commentMeta: {
    flex: 1,
    gap: 2,
  },
  authorText: {
    color: theme.colors.text.primary,
    fontSize: 14,
    fontWeight: '600',
  },
  dateText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.caption.size,
  },
  flaggedBadge: {
    padding: theme.space.xs,
    backgroundColor: theme.colors.state.warning + '22',
    borderRadius: theme.radius.sm,
  },
  commentText: {
    color: theme.colors.text.primary,
    fontSize: theme.type.body.size,
    lineHeight: theme.type.body.lineHeight,
    marginLeft: 36 + theme.space.md,
  },
  separator: {
    height: theme.space.lg,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.space.xxl * 2,
    gap: theme.space.md,
  },
  emptyTitle: {
    color: theme.colors.text.primary,
    fontSize: 18,
    fontWeight: '600',
  },
  emptyText: {
    color: theme.colors.text.secondary,
    fontSize: theme.type.body.size,
    textAlign: 'center',
  },
  inputContainer: {
    backgroundColor: theme.colors.bg.base,
    borderTopWidth: 1,
    borderTopColor: theme.colors.surface.border,
    padding: theme.space.lg,
    gap: theme.space.xs,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme.space.md,
    backgroundColor: theme.colors.surface.card,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    borderColor: theme.colors.surface.border,
    padding: theme.space.md,
  },
  input: {
    flex: 1,
    color: theme.colors.text.primary,
    fontSize: theme.type.body.size,
    maxHeight: 100,
    minHeight: 40,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.brand.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...applyShadow(2),
  },
  sendButtonDisabled: {
    backgroundColor: theme.colors.surface.chip,
    ...applyShadow(0),
  },
  charCount: {
    color: theme.colors.text.secondary,
    fontSize: 11,
    textAlign: 'right',
  },
});

export default CommentsScreen;

