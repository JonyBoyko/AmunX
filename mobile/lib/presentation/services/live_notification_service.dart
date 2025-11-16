import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveNotification {
  final String title;
  final String subtitle;
  final DateTime createdAt;

  const LiveNotification({
    required this.title,
    required this.subtitle,
    required this.createdAt,
  });
}

class LiveNotificationNotifier extends StateNotifier<LiveNotification?> {
  LiveNotificationNotifier() : super(null);

  Timer? _dismissTimer;

  void show(LiveNotification notification) {
    state = notification;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      state = null;
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}

final liveNotificationProvider =
    StateNotifierProvider<LiveNotificationNotifier, LiveNotification?>(
  (ref) => LiveNotificationNotifier(),
);
