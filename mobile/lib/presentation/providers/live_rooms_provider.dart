import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/repositories/live_repository.dart';
import '../models/live_room.dart';
import '../services/live_notification_service.dart';

final liveRoomsProvider =
    StateNotifierProvider<LiveRoomsNotifier, List<LiveRoom>>(
  (ref) => LiveRoomsNotifier(ref),
);

class LiveRoomsNotifier extends StateNotifier<List<LiveRoom>> {
  LiveRoomsNotifier(this._ref) : super(const []) {
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  final Ref _ref;
  Timer? _ticker;

  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    try {
      final repository = _ref.read(liveRepositoryProvider);
      final payload = await repository.fetchActiveRoomsRaw();
      final rooms = payload.map(LiveRoom.fromJson).toList();
      state = rooms;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to fetch live rooms',
        tag: 'LiveRoomsProvider',
        error: e,
        stackTrace: stack,
      );
    }
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
              title: '${room.hostName} live',
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
          room.copyWith(listeners: listeners)
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
