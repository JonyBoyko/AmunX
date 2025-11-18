import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/api/api_client.dart';
import '../../data/models/episode.dart';
import '../models/author_profile.dart';
import 'session_provider.dart';

final authorDirectoryProvider =
    StateNotifierProvider<AuthorDirectoryNotifier, Map<String, AuthorProfile>>(
  (ref) => AuthorDirectoryNotifier(ref),
);

final authorProfileProvider =
    Provider.family<AuthorProfile?, String>((ref, authorId) {
  return ref.watch(authorDirectoryProvider)[authorId];
});

class AuthorDirectoryNotifier
    extends StateNotifier<Map<String, AuthorProfile>> {
  AuthorDirectoryNotifier([this._ref]) : super(_seedAuthors());

  final Ref? _ref;
  final Set<String> _hydratedAuthors = <String>{};
  final Set<String> _pendingAuthors = <String>{};

  void syncWithEpisodes(List<Episode> episodes) {
    var changed = false;
    final missing = <String>{};
    final updated = Map<String, AuthorProfile>.from(state);

    for (final episode in episodes) {
      if (!updated.containsKey(episode.authorId)) {
        updated[episode.authorId] = _profileFromEpisode(episode);
        missing.add(episode.authorId);
        changed = true;
      }
    }

    if (changed) {
      state = updated;
      AppLogger.debug(
        'Author directory synced (${state.length} authors)',
        tag: 'AuthorDirectory',
      );
    }

    if (missing.isNotEmpty) {
      unawaited(_hydrateProfiles(missing));
    }
  }

  Future<void> toggleFollow(String authorId) async {
    final author = state[authorId];
    if (author == null) {
      return;
    }

    final nextFollowState = !author.isFollowed;
    final delta = nextFollowState ? 1 : -1;
    final optimistic = author.copyWith(
      isFollowed: nextFollowState,
      followers: max(0, author.followers + delta),
    );

    state = {
      ...state,
      authorId: optimistic,
    };

    final client = _authedClient();
    if (client == null) {
      return;
    }

    try {
      final response = await (nextFollowState
          ? client.followUser(authorId)
          : client.unfollowUser(authorId));
      final followers = _asInt(response['followers']);
      if (followers != null) {
        state = {
          ...state,
          authorId: optimistic.copyWith(followers: max(0, followers)),
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'toggleFollow failed for $authorId',
        tag: 'AuthorDirectory',
        error: e,
        stackTrace: stackTrace,
      );
      state = {
        ...state,
        authorId: author,
      };
    }
  }

  void boostLiveStatus(String authorId, bool isLive) {
    final author = state[authorId];
    if (author == null) {
      return;
    }
    state = {
      ...state,
      authorId: author.copyWith(isLive: isLive),
    };
  }

  Future<AuthorProfile?> refreshOwnProfile() async {
    final client = _authedClient();
    final ref = _ref;
    final userId = ref?.read(sessionProvider).user?.id;
    if (client == null || userId == null) {
      return null;
    }
    try {
      final response = await client.getMyProfile();
      final payload = response['profile'];
      if (payload is Map<String, dynamic>) {
        _applyRemoteProfiles([payload]);
        final id = payload['id'] as String?;
        if (id != null) {
          _hydratedAuthors.add(id);
        }
        return state[userId];
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'refreshOwnProfile failed',
        tag: 'AuthorDirectory',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Future<AuthorProfile?> updateOwnProfile({
    String? bio,
    Map<String, String>? socialLinks,
  }) async {
    if (bio == null && socialLinks == null) {
      return state[_ref?.read(sessionProvider).user?.id];
    }
    final client = _authedClient();
    final ref = _ref;
    final userId = ref?.read(sessionProvider).user?.id;
    if (client == null || userId == null) {
      return null;
    }
    final body = <String, dynamic>{};
    if (bio != null) {
      body['bio'] = bio;
    }
    if (socialLinks != null) {
      body['social_links'] = socialLinks;
    }
    try {
      final response = await client.updateMyProfile(body);
      final payload = response['profile'];
      if (payload is Map<String, dynamic>) {
        _applyRemoteProfiles([payload]);
        final id = payload['id'] as String?;
        if (id != null) {
          _hydratedAuthors.add(id);
        }
        return state[userId];
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'updateOwnProfile failed',
        tag: 'AuthorDirectory',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    return null;
  }

  Future<void> _hydrateProfiles(Set<String> authorIds) async {
    final client = _authedClient();
    if (client == null) {
      return;
    }

    final newIds = authorIds
        .where(
          (id) =>
              !_hydratedAuthors.contains(id) && !_pendingAuthors.contains(id),
        )
        .toList();
    if (newIds.isEmpty) {
      return;
    }

    _pendingAuthors.addAll(newIds);
    try {
      for (final chunk in _chunk(newIds, 20)) {
        final profileData = await client.getAuthorProfiles(chunk);
        _applyRemoteProfiles(profileData);
        _hydratedAuthors.addAll(chunk);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'hydrateProfiles failed',
        tag: 'AuthorDirectory',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _pendingAuthors.removeAll(newIds);
    }
  }

  void _applyRemoteProfiles(List<dynamic> payloads) {
    if (payloads.isEmpty) {
      return;
    }
    final updated = Map<String, AuthorProfile>.from(state);
    var changed = false;

    for (final entry in payloads) {
      final map = entry is Map<String, dynamic>
          ? entry
          : Map<String, dynamic>.from(entry as Map);
      final id = map['id'] as String?;
      if (id == null) {
        continue;
      }

      final existing = updated[id];
      final displayName = (map['display_name'] as String?) ??
          existing?.displayName ??
          'Creator';
      final handle =
          (map['handle'] as String?) ?? existing?.handle ?? '@voice.creator';
      final bio =
          (map['bio'] as String?) ?? existing?.bio ?? 'Creator on Moweton';
      final avatarUrl =
          (map['avatar'] as String?) ?? existing?.avatarUrl ?? '';
      final avatarEmoji =
          existing?.avatarEmoji ?? _avatarFromName(displayName);
      final followers = _asInt(map['followers']) ?? existing?.followers ?? 0;
      final following = _asInt(map['following']) ?? existing?.following ?? 0;
      final posts = _asInt(map['posts']) ?? existing?.posts ?? 0;
      final isFollowing =
          (map['is_following'] as bool?) ?? existing?.isFollowed ?? false;
      final socialLinks =
          _parseSocialLinks(map['social_links']) ?? existing?.socialLinks ?? {};

      final profile = (existing ??
              AuthorProfile(
                id: id,
                displayName: displayName,
                handle: handle,
                bio: bio,
                avatarEmoji: avatarEmoji,
                avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
                followers: followers,
                following: following,
                posts: posts,
                isFollowed: isFollowing,
                isLive: existing?.isLive ?? false,
                badges: existing?.badges ?? const [],
                socialLinks: socialLinks,
              ))
          .copyWith(
        displayName: displayName,
        handle: handle,
        bio: bio,
        avatarEmoji: avatarEmoji,
        avatarUrl: avatarUrl.isEmpty ? existing?.avatarUrl : avatarUrl,
        followers: followers,
        following: following,
        isFollowed: isFollowing,
        posts: posts,
        socialLinks: socialLinks,
      );

      updated[id] = profile;
      changed = true;
    }

    if (changed) {
      state = updated;
    }
  }

  ApiClient? _authedClient() {
    final ref = _ref;
    if (ref == null) {
      return null;
    }
    final token = ref.read(sessionProvider).token;
    if (token == null) {
      return null;
    }
    return createApiClient(token: token);
  }
}

Map<String, AuthorProfile> _seedAuthors() {
  return {
    for (final author in _demoAuthors) author.id: author,
  };
}

const List<AuthorProfile> _demoAuthors = [
  AuthorProfile(
    id: 'creator-olena',
    displayName: 'Olena Walks',
    handle: '@olena.walks',
    bio: 'Morning walk recaps and mindful notes.',
    avatarEmoji: 'O',
    avatarUrl: null,
    followers: 1820,
    following: 312,
    posts: 64,
    isFollowed: true,
    isLive: false,
    badges: ['Walk Club'],
  ),
  AuthorProfile(
    id: 'creator-danylo',
    displayName: 'Danylo Fedan',
    handle: '@fedan',
    bio: 'Product lead sharing daily standups and experiments.',
    avatarEmoji: 'D',
    avatarUrl: null,
    followers: 940,
    following: 188,
    posts: 41,
    isFollowed: false,
    isLive: true,
    badges: ['Live now'],
  ),
  AuthorProfile(
    id: 'creator-maria',
    displayName: 'Maria Audio',
    handle: '@maria.audio',
    bio: 'Async team check-ins and weekend planning capsules.',
    avatarEmoji: 'M',
    avatarUrl: null,
    followers: 2210,
    following: 503,
    posts: 88,
    isFollowed: true,
    isLive: false,
    badges: ['Pro host'],
  ),
];

AuthorProfile _profileFromEpisode(Episode episode) {
  final hash = episode.authorId.hashCode;
  final stickers = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  final sticker = stickers[hash.abs() % stickers.length];
  final name = _generatedNames[hash.abs() % _generatedNames.length];
  final handle = '@${name.split(' ').first.toLowerCase()}${hash.abs() % 1000}';
  final followers = 300 + (hash.abs() % 1500);
  final following = 40 + (hash.abs() % 200);
  final posts = 8 + (hash.abs() % 90);
  final badges = followers > 1500 ? ['Top Creator'] : <String>[];

  return AuthorProfile(
    id: episode.authorId,
    displayName: name,
    handle: handle,
    bio: 'Community-generated author synced from recent episodes.',
    avatarEmoji: sticker,
    avatarUrl: null,
    followers: followers,
    following: following,
    posts: posts,
    isFollowed: hash.isEven,
    isLive: episode.isLive,
    badges: badges,
  );
}

const _generatedNames = [
  'Marta Dovzhenko',
  'Andrii Koval',
  'Larysa Prymak',
  'Petro Horbunov',
  'Sofiia Romanenko',
  'Yuliia Yatsenko',
  'Oleh Ponomarenko',
  'Natalia Zakharchuk',
];

Iterable<List<String>> _chunk(List<String> ids, int size) sync* {
  for (var i = 0; i < ids.length; i += size) {
    var end = i + size;
    if (end > ids.length) {
      end = ids.length;
    }
    yield ids.sublist(i, end);
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String _avatarFromName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}

Map<String, String>? _parseSocialLinks(dynamic value) {
  if (value is Map) {
    final result = <String, String>{};
    value.forEach((key, raw) {
      final k = key?.toString() ?? '';
      final v = raw?.toString() ?? '';
      if (k.isEmpty || v.trim().isEmpty) {
        return;
      }
      result[k] = v.trim();
    });
    if (result.isNotEmpty) {
      return result;
    }
  }
  return null;
}
