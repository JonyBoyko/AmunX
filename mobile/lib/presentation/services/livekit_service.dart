import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../core/logging/app_logger.dart';
import '../../data/api/api_client.dart';
import '../../data/models/live_session.dart';
import '../models/live_room.dart';
import '../providers/live_rooms_provider.dart';
import '../providers/session_provider.dart';
import 'livekit_reconnect_manager.dart';
import 'transcript_parser.dart';

final livekitControllerProvider =
    StateNotifierProvider<LivekitController, LivekitSessionState>(
  (ref) => LivekitController(ref),
);

enum LivekitStatus { idle, connecting, reconnecting, connected, error }

class LivekitSessionState {
  final LivekitStatus status;
  final bool isHost;
  final LiveSession? session;
  final int listenerCount;
  final String? error;
  final List<TranscriptSegment> transcript;

  const LivekitSessionState({
    required this.status,
    required this.isHost,
    required this.listenerCount,
    this.session,
    this.error,
    this.transcript = const [],
  });

  const LivekitSessionState._({
    required this.status,
    required this.isHost,
    required this.listenerCount,
  })  : session = null,
        error = null,
        transcript = const [];

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
    List<TranscriptSegment>? transcript,
  }) {
    return LivekitSessionState(
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
      session: clearSession ? null : (session ?? this.session),
      listenerCount: listenerCount ?? this.listenerCount,
      error: error,
      transcript: transcript ?? this.transcript,
    );
  }
}

class LivekitController extends StateNotifier<LivekitSessionState> {
  LivekitController(this._ref) : super(LivekitSessionState.idle());

  final Ref _ref;
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  Timer? _statsTimer;
  Timer? _reconnectTimer;
  _JoinContext? _lastJoin;
  final LivekitReconnectManager _reconnectManager =
      LivekitReconnectManager();

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
    state = const LivekitSessionState(
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
              emoji: '??',
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
      unawaited(_ref.read(liveRoomsProvider.notifier).refresh());
    }
  }

  Future<void> joinSession(String sessionId) async {
    await _disconnectRoom();
    state = const LivekitSessionState(
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
    final room = Room();
    await _roomEvents?.dispose();
    final listener = room.createListener();
    listener.on<RoomEvent>(_handleRoomEvent);
    _roomEvents = listener;
    await room.connect(join.url, join.token);
    final localParticipant = room.localParticipant;
    if (localParticipant != null) {
      await localParticipant.setMicrophoneEnabled(isHost);
    }
    _room = room;
    _lastJoin = _JoinContext(join, isHost);
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _emitStats(),
    );
    if (_reconnectManager.attempts > 0) {
      AppLogger.info(
        'LiveKit reconnect successful after ${_reconnectManager.attempts} attempt(s)',
        tag: 'LiveKit',
      );
    }
    _reconnectManager.reset();

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
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _roomEvents?.dispose();
    _roomEvents = null;
    if (_room != null) {
      await _room?.disconnect();
      await _room?.dispose();
      _room = null;
    }
    _lastJoin = null;
    _reconnectManager.reset();
  }

  int _currentListenerCount() {
    final room = _room;
    if (room == null) {
      return 0;
    }
    // В новій версії livekit_client використовується remoteParticipants
    // +1 для local participant (host)
    return room.remoteParticipants.length + (room.localParticipant != null ? 1 : 0);
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

  void _handleRoomEvent(RoomEvent event) {
    if (event is ParticipantConnectedEvent ||
        event is ParticipantDisconnectedEvent) {
      _emitStats();
    } else if (event is DataReceivedEvent) {
      _handleTranscriptPacket(event.data);
    } else if (event is RoomReconnectingEvent) {
      state = state.copyWith(status: LivekitStatus.reconnecting);
    } else if (event is RoomDisconnectedEvent) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_lastJoin == null || !_reconnectManager.canAttempt) {
      state = state.copyWith(
        status: LivekitStatus.error,
        error: 'connectivity_lost',
      );
      return;
    }
    state = state.copyWith(status: LivekitStatus.reconnecting);
    final attemptIndex = _reconnectManager.attempts + 1;
    final delay = _reconnectManager.nextDelay();
    AppLogger.warning(
      'LiveKit reconnect attempt $attemptIndex/${_reconnectManager.maxAttempts} scheduled in ${delay.inSeconds}s',
      tag: 'LiveKit',
    );
    _reconnectManager.markAttempt();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _attemptReconnect);
  }

  Future<void> _attemptReconnect() async {
    final context = _lastJoin;
    if (context == null) {
      return;
    }
    try {
      await _connect(context.join, isHost: context.isHost);
    } catch (e, stackTrace) {
      AppLogger.error(
        'LiveKit reconnect failed',
        tag: 'LiveKit',
        error: e,
        stackTrace: stackTrace,
      );
      _scheduleReconnect();
    }
  }

  void _handleTranscriptPacket(List<int> data) {
    final message = decodeTranscriptMessage(data);
    if (message == null || message.text.isEmpty) {
      return;
    }
    final updated = List<TranscriptSegment>.from(state.transcript)
      ..add(
        TranscriptSegment(
          text: message.text,
          timestamp: message.timestamp ?? DateTime.now(),
          speaker: message.speaker,
          language: message.displayLanguage,
          isTranslation: message.isTranslation,
        ),
      );
    const maxSegments = 20;
    final trimmed = updated.length > maxSegments
        ? updated.sublist(updated.length - maxSegments)
        : updated;
    state = state.copyWith(transcript: trimmed);
  }
}

class _JoinContext {
  _JoinContext(this.join, this.isHost);
  final LiveSessionJoin join;
  final bool isHost;
}

class TranscriptSegment {
  const TranscriptSegment({
    required this.text,
    required this.timestamp,
    this.speaker,
    this.language,
    this.isTranslation = false,
  });

  final String text;
  final DateTime timestamp;
  final String? speaker;
  final String? language;
  final bool isTranslation;

  String get speakerLabel => speaker == null || speaker!.trim().isEmpty
      ? 'Host'
      : speaker!;
}
