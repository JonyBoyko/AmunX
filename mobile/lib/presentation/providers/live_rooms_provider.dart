import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/live_room.dart';
import '../services/live_notification_service.dart';

final liveRoomsProvider =
    StateNotifierProvider<LiveRoomsNotifier, List<LiveRoom>>(
  (ref) => LiveRoomsNotifier(ref),
);

class LiveRoomsNotifier extends StateNotifier<List<LiveRoom>> {
  LiveRoomsNotifier(this._ref) : super(_seedRooms()) {
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  final Ref _ref;
  Timer? _ticker;
  final _random = Random();

  void _tick() {
    state = [
      for (final room in state)
        room.isSimulated
            ? room.copyWith(
                listeners: _normalizeListeners(room.listeners),
              )
            : room,
    ];
  }

  int _normalizeListeners(int current) {
    final delta = _random.nextInt(8) - 3;
    final next = current + delta;
    return next.clamp(25, 180);
  }

  void startHosting(LiveRoom room) {
    final alreadyLive = state.any((r) => r.id == room.id);
    if (alreadyLive) {
      state = [
        for (final existing in state)
          if (existing.id == room.id) room else existing,
      ];
    } else {
      state = [room, ...state];
    }
    if (room.isFollowedHost) {
      _ref.read(liveNotificationProvider.notifier).show(
            LiveNotification(
              title: ' live',
              subtitle: room.topic,
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  void stopHosting(String roomId) {
    state = state.where((room) => room.id != roomId).toList();
  }

  void updateListenerCount(String roomId, int listeners) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(listeners: max(0, listeners))
        else
          room,
    ];
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

List<LiveRoom> _seedRooms() {
  final now = DateTime.now();
  return [
    LiveRoom(
      id: 'live-ai-town',
      hostId: 'creator-olena',
      hostName: 'Олена Walks',
      handle: '@olena.walks',
      topic: 'AI & walkcasts',
      emoji: '🚶',
      listeners: 132,
      city: 'Kyiv',
      isFollowedHost: true,
      startedAt: now.subtract(const Duration(minutes: 8)),
      tags: const ['AI', 'walkcast'],
      isSimulated: true,
    ),
    LiveRoom(
      id: 'live-biz-late',
      hostId: 'creator-danylo',
      hostName: 'Данило Builder',
      handle: '@fedan',
      topic: 'Late-night build in public',
      emoji: '🚀',
      listeners: 88,
      city: 'Lviv',
      isFollowedHost: false,
      startedAt: now.subtract(const Duration(minutes: 3)),
      tags: const ['founders', 'build'],
      isSimulated: true,
    ),
    LiveRoom(
      id: 'live-maria-calm',
      hostId: 'creator-maria',
      hostName: 'Марія Calm',
      handle: '@maria.audio',
      topic: 'Mindful night stream',
      emoji: '🧘',
      listeners: 64,
      city: 'Warsaw',
      isFollowedHost: true,
      startedAt: now.subtract(const Duration(minutes: 15)),
      tags: const ['wellness'],
      isSimulated: true,
    ),
  ];
}
