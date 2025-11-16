import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/presentation/models/live_room.dart';
import 'package:moweton_flutter/presentation/providers/live_rooms_provider.dart';
import 'package:moweton_flutter/presentation/services/live_notification_service.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('startHosting inserts new room and triggers notification for followed',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final room = LiveRoom(
      id: 'test-room',
      hostId: 'creator-olena',
      hostName: 'Олена',
      handle: '@olena',
      topic: 'Test Live',
      emoji: '🎙️',
      listeners: 50,
      city: 'Київ',
      isFollowedHost: true,
      startedAt: DateTime.now(),
      tags: const ['test'],
    );

    notifier.startHosting(room);

    final rooms = container.read(liveRoomsProvider);
    expect(rooms.any((r) => r.id == 'test-room'), isTrue);

    final notification = container.read(liveNotificationProvider);
    expect(notification, isNotNull);
    expect(notification?.title, contains('Олена'));
  });

  test('stopHosting removes room', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveRoomsProvider.notifier);
    final initialId = container.read(liveRoomsProvider).first.id;

    notifier.stopHosting(initialId);

    final rooms = container.read(liveRoomsProvider);
    expect(rooms.any((room) => room.id == initialId), isFalse);
  });

  test('ticker updates listeners over time', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(liveRoomsProvider).first.listeners;
    await Future<void>.delayed(const Duration(seconds: 6));
    final updated = container.read(liveRoomsProvider).first.listeners;
    expect(updated, isNot(initial));
  }, timeout: const Timeout(Duration(seconds: 10)));
}
