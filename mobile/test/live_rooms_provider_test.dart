import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/repositories/live_repository.dart';
import 'package:moweton_flutter/presentation/models/live_room.dart';
import 'package:moweton_flutter/presentation/providers/live_rooms_provider.dart';
import 'package:moweton_flutter/presentation/services/live_notification_service.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> createContainer({
    List<List<Map<String, dynamic>>>? responses,
  }) async {
    final container = ProviderContainer(
      overrides: [
        liveRepositoryProvider.overrideWith(
          (ref) => _FakeLiveRepository(
            ref,
            responses ?? _defaultResponses,
          ),
        ),
      ],
    );
    await container.read(liveRoomsProvider.notifier).refresh();
    return container;
  }

  test('startHosting inserts new room and triggers notification for followed',
      () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final room = LiveRoom(
      id: 'test-room',
      hostId: 'creator-olena',
      hostName: 'Olena',
      handle: '@olena',
      topic: 'Test Live',
      emoji: 'mic',
      listeners: 50,
      city: 'Kyiv',
      isFollowedHost: true,
      startedAt: DateTime.now(),
      tags: const ['test'],
    );

    notifier.startHosting(room);

    final rooms = container.read(liveRoomsProvider);
    expect(rooms.any((r) => r.id == 'test-room'), isTrue);

    final notification = container.read(liveNotificationProvider);
    expect(notification, isNotNull);
    expect(notification?.title, contains('live'));
  });

  test('stopHosting removes room', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final initialId = container.read(liveRoomsProvider).first.id;

    notifier.stopHosting(initialId);

    final rooms = container.read(liveRoomsProvider);
    expect(rooms.any((room) => room.id == initialId), isFalse);
  });

  test('ticker updates listeners over time', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final initial = container.read(liveRoomsProvider).first.listeners;

    await notifier.refresh();
    final updated = container.read(liveRoomsProvider).first.listeners;

    expect(
      updated,
      isNot(initial),
      reason: 'listeners should change after another refresh',
    );
  });

  test('updateListenerCount overwrites realtime rooms', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final room = LiveRoom(
      id: 'livekit-room',
      hostId: 'creator-live',
      hostName: 'Live Host',
      handle: '@live.host',
      topic: 'Realtime stream',
      emoji: 'mic',
      listeners: 1,
      city: 'Online',
      isFollowedHost: false,
      startedAt: DateTime.now(),
      tags: const ['live'],
      isSimulated: false,
    );

    notifier.startHosting(room);
    notifier.updateListenerCount('livekit-room', 42);

    final updatedRoom = container
        .read(liveRoomsProvider)
        .firstWhere((r) => r.id == 'livekit-room');
    expect(updatedRoom.listeners, 42);
  });
}

class _FakeLiveRepository extends LiveRepository {
  _FakeLiveRepository(super.ref, this.responses);

  final List<List<Map<String, dynamic>>> responses;
  int _callIndex = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoomsRaw({int limit = 20}) async {
    final index =
        _callIndex < responses.length ? _callIndex : responses.length - 1;
    _callIndex++;
    return responses[index];
  }
}

final _defaultResponses = <List<Map<String, dynamic>>>[
  [
    {
      'id': 'room-1',
      'host_id': 'creator-1',
      'host_name': 'Creator One',
      'host_handle': '@creator.one',
      'title': 'Morning AMA',
      'mask': 'basic',
      'listeners': 25,
      'city': 'Kyiv',
      'is_followed_host': true,
      'started_at': '2024-03-01T10:00:00Z',
      'tags': ['product'],
    },
    {
      'id': 'room-2',
      'host_id': 'creator-2',
      'host_name': 'Creator Two',
      'host_handle': '@creator.two',
      'title': 'Design sync',
      'mask': 'studio',
      'listeners': 10,
      'city': 'Lviv',
      'is_followed_host': false,
      'started_at': '2024-03-01T08:00:00Z',
      'tags': ['design'],
    },
  ],
  [
    {
      'id': 'room-1',
      'host_id': 'creator-1',
      'host_name': 'Creator One',
      'host_handle': '@creator.one',
      'title': 'Morning AMA',
      'mask': 'basic',
      'listeners': 40,
      'city': 'Kyiv',
      'is_followed_host': true,
      'started_at': '2024-03-01T10:00:00Z',
      'tags': ['product'],
    },
    {
      'id': 'room-2',
      'host_id': 'creator-2',
      'host_name': 'Creator Two',
      'host_handle': '@creator.two',
      'title': 'Design sync',
      'mask': 'studio',
      'listeners': 12,
      'city': 'Lviv',
      'is_followed_host': false,
      'started_at': '2024-03-01T08:00:00Z',
      'tags': ['design'],
    },
  ],
  [
    {
      'id': 'room-1',
      'host_id': 'creator-1',
      'host_name': 'Creator One',
      'host_handle': '@creator.one',
      'title': 'Morning AMA',
      'mask': 'basic',
      'listeners': 55,
      'city': 'Kyiv',
      'is_followed_host': true,
      'started_at': '2024-03-01T10:00:00Z',
      'tags': ['product'],
    },
    {
      'id': 'room-2',
      'host_id': 'creator-2',
      'host_name': 'Creator Two',
      'host_handle': '@creator.two',
      'title': 'Design sync',
      'mask': 'studio',
      'listeners': 18,
      'city': 'Lviv',
      'is_followed_host': false,
      'started_at': '2024-03-01T08:00:00Z',
      'tags': ['design'],
    },
  ],
];
