import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/api/api_client.dart';
import '../providers/session_provider.dart';
import '../services/live_notification_service.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref);
});

final pushBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(pushServiceProvider).bootstrap();
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService(this._ref) {
    _ref.listen<SessionState>(
      sessionProvider,
      (previous, next) {
        _handleSessionChanged(previous, next);
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenSubscription;
  String? _currentFcmToken;
  String? _registeredToken;
  bool _initialized = false;

  Future<void> bootstrap() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _initializeLocalNotifications();
    await _requestPermissions();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        AppLogger.info('FCM token refreshed', tag: 'PushService');
        _currentFcmToken = token;
        unawaited(_registerWithBackend(token));
      },
    );

    _currentFcmToken = await _messaging.getToken();
    if (_currentFcmToken != null) {
      await _registerWithBackend(_currentFcmToken!);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    const androidChannel = AndroidNotificationChannel(
      'moweton_default',
      'Moweton Alerts',
      description: 'Live & push alerts',
      importance: Importance.max,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info(
      'Push permission status: ${settings.authorizationStatus}',
      tag: 'PushService',
    );
  }

  void _handleSessionChanged(SessionState? previous, SessionState next) {
    if (next.isAuthenticated && next.token != null && _currentFcmToken != null) {
      unawaited(_registerWithBackend(_currentFcmToken!));
    } else if ((previous?.isAuthenticated ?? false) &&
        !(next.isAuthenticated) &&
        _registeredToken != null &&
        previous?.token != null) {
      unawaited(_unregisterFromBackend(
        authToken: previous!.token!,
        deviceToken: _registeredToken!,
      ),);
      _registeredToken = null;
    }
  }

  Future<void> _registerWithBackend(String token) async {
    final session = _ref.read(sessionProvider);
    if (!session.isAuthenticated || session.token == null) {
      AppLogger.debug(
        'Skipping push registration until auth completes',
        tag: 'PushService',
      );
      return;
    }
    try {
      final api = createApiClient(token: session.token);
      await api.registerPushDevice(
        token: token,
        platform: _platform,
        deviceId: await _deviceId(),
        locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      );
      _registeredToken = token;
      AppLogger.info('Push token registered with backend', tag: 'PushService');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to register push token',
        tag: 'PushService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _unregisterFromBackend({
    required String authToken,
    required String deviceToken,
  }) async {
    try {
      final api = createApiClient(token: authToken);
      await api.unregisterPushDevice(deviceToken);
      AppLogger.info('Push token removed from backend', tag: 'PushService');
    } catch (e) {
      AppLogger.warning(
        'Failed to unregister push token',
        tag: 'PushService',
        error: e,
      );
    }
  }

  Future<String?> _deviceId() async {
    if (kIsWeb) {
      return null;
    }
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return info.id;
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return info.identifierForVendor;
    }
    return null;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Moweton';
    final body = notification?.body ?? message.data['body'] ?? '';

    _notifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'moweton_default',
          'Moweton Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    if (message.data['type'] == 'live_start') {
      _ref.read(liveNotificationProvider.notifier).show(
            LiveNotification(
              title: '$title 🔴',
              subtitle: body,
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] == 'live_start') {
      _ref.read(liveNotificationProvider.notifier).show(
            LiveNotification(
              title: message.notification?.title ?? 'Live started',
              subtitle: message.notification?.body ?? '',
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'android';
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
  }
}
