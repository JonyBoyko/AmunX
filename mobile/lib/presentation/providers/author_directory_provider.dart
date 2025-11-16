import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/episode.dart';
import '../models/author_profile.dart';

final authorDirectoryProvider =
    StateNotifierProvider<AuthorDirectoryNotifier, Map<String, AuthorProfile>>(
  (ref) => AuthorDirectoryNotifier(),
);

final authorProfileProvider =
    Provider.family<AuthorProfile?, String>((ref, authorId) {
  return ref.watch(authorDirectoryProvider)[authorId];
});

class AuthorDirectoryNotifier
    extends StateNotifier<Map<String, AuthorProfile>> {
  AuthorDirectoryNotifier() : super(_seedAuthors());

  void syncWithEpisodes(List<Episode> episodes) {
    var changed = false;
    final updated = Map<String, AuthorProfile>.from(state);
    for (final episode in episodes) {
      if (!updated.containsKey(episode.authorId)) {
        updated[episode.authorId] = _profileFromEpisode(episode);
        changed = true;
      }
    }
    if (changed) {
      state = updated;
      AppLogger.debug('Author directory synced (${state.length} authors)',
          tag: 'AuthorDirectory');
    }
  }

  void toggleFollow(String authorId) {
    final author = state[authorId];
    if (author == null) return;
    final nextFollowState = !author.isFollowed;
    final delta = nextFollowState ? 1 : -1;
    state = {
      ...state,
      authorId: author.copyWith(
        isFollowed: nextFollowState,
        followers: max(0, author.followers + delta),
      ),
    };
  }

  void boostLiveStatus(String authorId, bool isLive) {
    final author = state[authorId];
    if (author == null) return;
    state = {
      ...state,
      authorId: author.copyWith(isLive: isLive),
    };
  }
}

Map<String, AuthorProfile> _seedAuthors() {
  return {
    for (final author in _demoAuthors) author.id: author,
  };
}

final List<AuthorProfile> _demoAuthors = [
  AuthorProfile(
    id: 'creator-olena',
    displayName: 'Олена Лісова',
    handle: '@olena.walks',
    bio: 'Walk-подкасти про підприємництво та ментальне здоровʼя.',
    avatarEmoji: '🌿',
    followers: 1820,
    following: 312,
    posts: 64,
    isFollowed: true,
    isLive: false,
    badges: const ['✨ Топ 1 тижня'],
  ),
  AuthorProfile(
    id: 'creator-danylo',
    displayName: 'Данило Федоров',
    handle: '@fedan',
    bio: 'Щоденні нотатки фаундера, бекстейдж запусків у Moweton.',
    avatarEmoji: '🚀',
    followers: 940,
    following: 188,
    posts: 41,
    isFollowed: false,
    isLive: true,
    badges: const ['LIVE'],
  ),
  AuthorProfile(
    id: 'creator-maria',
    displayName: 'Марія Перегуда',
    handle: '@maria.audio',
    bio: 'Медитації та голосові щоденники для продуктивності.',
    avatarEmoji: '🧘',
    followers: 2210,
    following: 503,
    posts: 88,
    isFollowed: true,
    isLive: false,
    badges: const ['✨ Pro'],
  ),
];

AuthorProfile _profileFromEpisode(Episode episode) {
  final hash = episode.authorId.hashCode;
  final stickers = ['🎧', '🎙️', '🌀', '🦊', '🌌', '🦉', '💡'];
  final sticker = stickers[hash.abs() % stickers.length];
  final name = _generatedNames[hash.abs() % _generatedNames.length];
  final handle = '@${name.split(' ').first.toLowerCase()}${hash.abs() % 1000}';
  final followers = 300 + (hash.abs() % 1500);
  final following = 40 + (hash.abs() % 200);
  final posts = 8 + (hash.abs() % 90);
  final badges = followers > 1500 ? ['🔥 Тренди поруч'] : <String>[];

  return AuthorProfile(
    id: episode.authorId,
    displayName: name,
    handle: handle,
    bio: 'Автор щоденників та мікроподкастів у Moweton.',
    avatarEmoji: sticker,
    followers: followers,
    following: following,
    posts: posts,
    isFollowed: hash.isEven,
    isLive: episode.isLive,
    badges: badges,
  );
}

const _generatedNames = [
  'Антон Ромащенко',
  'Софія Дорошенко',
  'Ілля Мельник',
  'Оксана Ярмолюк',
  'Іра Жадан',
  'Марко Пшеничний',
  'Влад Гончар',
  'Аліна Кулик',
];
