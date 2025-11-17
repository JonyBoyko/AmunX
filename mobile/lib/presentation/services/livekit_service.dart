import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../core/logging/app_logger.dart';
import '../../data/api/api_client.dart';
import '../../data/models/live_session.dart';
import '../models/live_room.dart';
import '../providers/live_rooms_provider.dart';
import '../providers/session_provider.dart';

final livekitControllerProvider =
    StateNotifierProvider<LivekitController, LivekitSessionState>(
  (ref) => LivekitController(ref),
);

enum LivekitStatus { idle, connecting, connected, error }

class LivekitSessionState {
  final LivekitStatus status;
  final bool isHost;
  final LiveSession? session;
  final int listenerCount;
  final String? error;

  const LivekitSessionState({
    required this.status,
    required this.isHost,
    required this.listenerCount,
    this.session,
    this.error,
  });

  const LivekitSessionState._({
    required this.status,
    required this.isHost,
    required this.listenerCount,
    this.session,
    this.error,
  });

  factory LivekitSessionState.idle() {
    return const LivekitSessionState._(
      status: LivekitStatus.idle,
      isHost: false,
      listenerCount: 0,
    );
  }

  LivekitSessionState copyWith({
    LivekitStatus? status,
    bool? isHost,
    LiveSession? session,
    bool clearSession = false,
    int? listenerCount,
    String? error,
  }) {
    return LivekitSessionState(
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
      session: clearSession ? null : (session ?? this.session),
      listenerCount: listenerCount ?? this.listenerCount,
      error: error,
    );
  }
}

class LivekitController extends StateNotifier<LivekitSessionState> {
  LivekitController(this._ref) : super(LivekitSessionState.idle());

  final Ref _ref;
  Room? _room;
  Timer? _statsTimer;

  Future<void> startHosting({
    String? title,
    String? topicId,
  }) async {
    final sessionState = _ref.read(sessionProvider);
    final token = sessionState.token;
    if (token == null) {
      throw StateError('auth_required');
    }
    await _disconnectRoom();
    state = LivekitSessionState(
      status: LivekitStatus.connecting,
      isHost: true,
      session: null,
      listenerCount: 0,
      error: null,
    );
    try {
      final client = createApiClient(token: token);
      final payload = await client.createLiveSession(
        title: title ?? 'Live with ${sessionState.user?.email ?? 'Moweton'}',
        topicId: topicId,
      );
      final join = LiveSessionJoin.fromJson(payload);
      await _connect(join, isHost: true);

      final user = sessionState.user;
      _ref.read(liveRoomsProvider.notifier).startHosting(
            LiveRoom(
              id: join.session.id,
              hostId: user?.id ?? join.session.hostId,
              hostName: user?.email ?? 'You',
              handle: user?.email ?? '@you',
              topic: join.session.title ?? 'Live session',
              emoji: '🎤',
              listeners: 1,
              city: 'Online',
              isFollowedHost: true,
              startedAt: join.session.startedAt,
              tags: const ['live'],
              isSimulated: false,
            ),
          );
    } catch (e, stackTrace) {
      AppLogger.error(
        'startHosting failed',
        tag: 'LiveKit',
        error: e,
        stackTrace: stackTrace,
      );
      state = LivekitSessionState(
        status: LivekitStatus.error,
        isHost: true,
        session: null,
        listenerCount: 0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> endHosting() async {
    final session = state.session;
    final token = _ref.read(sessionProvider).token;
    await _disconnectRoom();
    state = LivekitSessionState.idle();
    if (session != null && token != null) {
      try {
        final client = createApiClient(token: token);
        await client.endLiveSession(session.id);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'endLiveSession failed',
          tag: 'LiveKit',
          error: e,
          stackTrace: stackTrace,
        );
      }
      _ref.read(liveRoomsProvider.notifier).stopHosting(session.id);
    }
  }

  Future<void> joinSession(String sessionId) async {
    await _disconnectRoom();
    state = LivekitSessionState(
      status: LivekitStatus.connecting,
      isHost: false,
      session: null,
      listenerCount: 0,
      error: null,
    );
    try {
      final token = _ref.read(sessionProvider).token;
      final client = createApiClient(token: token);
      final payload = await client.getLiveSession(sessionId);
      final join = LiveSessionJoin.fromJson(payload);
      await _connect(join, isHost: false);
    } catch (e, stackTrace) {
      AppLogger.error(
        'joinSession failed',
        tag: 'LiveKit',
        error: e,
        stackTrace: stackTrace,
      );
      state = LivekitSessionState(
        status: LivekitStatus.error,
        isHost: false,
        session: null,
        listenerCount: 0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> leave() async {
    await _disconnectRoom();
    state = LivekitSessionState.idle();
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'setMicrophoneEnabled failed',
        tag: 'LiveKit',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _connect(
    LiveSessionJoin join, {
    required bool isHost,
  }) async {
    final room = await LiveKitClient.connect(join.url, join.token);
    if (isHost) {
      await room.localParticipant?.setMicrophoneEnabled(true);
    } else {
      await room.localParticipant?.setMicrophoneEnabled(false);
    }
    _room = room;
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _emitStats(),
    );

    state = LivekitSessionState(
      status: LivekitStatus.connected,
      isHost: isHost,
      session: join.session,
      listenerCount: _currentListenerCount(),
      error: null,
    );
    _emitStats(); // immediate update
  }

  Future<void> _disconnectRoom() async {
    _statsTimer?.cancel();
    _statsTimer = null;
    if (_room != null) {
      await _room?.disconnect();
      await _room?.dispose();
      _room = null;
    }
  }

  int _currentListenerCount() {
    final room = _room;
    if (room == null) {
      return 0;
    }
    return room.remoteParticipants.length;
  }

  void _emitStats() {
    final session = state.session;
    if (session == null) {
      return;
    }
    final listeners = _currentListenerCount();
    state = state.copyWith(listenerCount: listeners);
    _ref
        .read(liveRoomsProvider.notifier)
        .updateListenerCount(session.id, listeners);
  }
}
