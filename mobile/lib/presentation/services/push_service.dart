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

final pushStatusProvider =
    StateNotifierProvider<PushStatusNotifier, PushRegistrationState>(
  (ref) => PushStatusNotifier(),
);

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
  PushStatusNotifier get _statusNotifier =>
      _ref.read(pushStatusProvider.notifier);

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
    final settings = await _messaging.getNotificationSettings();
    _statusNotifier.updateSettings(settings);
    if (settings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      await _requestPermissions();
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        AppLogger.info('FCM token refreshed', tag: 'PushService');
        _currentFcmToken = token;
        _statusNotifier.setFirebaseToken(token);
        unawaited(_registerWithBackend(token));
      },
    );

    _currentFcmToken = await _messaging.getToken();
    if (_currentFcmToken != null) {
      _statusNotifier.setFirebaseToken(_currentFcmToken);
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

  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info(
      'Push permission status: ${settings.authorizationStatus}',
      tag: 'PushService',
    );
    _statusNotifier.updateSettings(settings);
    return settings;
  }

  Future<void> refreshPermissions() async {
    final settings = await _messaging.getNotificationSettings();
    _statusNotifier.updateSettings(settings);
  }

  Future<void> requestUserPermission() => _requestPermissions();

  Future<void> openSystemSettings() async {
    try {
      await _requestPermissions();
    } catch (error, stack) {
      AppLogger.warning(
        'Failed to open push settings',
        tag: 'PushService',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> reRegisterDevice() async {
    final token = _currentFcmToken ?? await _messaging.getToken();
    if (token == null) {
      _statusNotifier.setError('FCM token unavailable');
      return;
    }
    await _registerWithBackend(token);
  }

  Future<void> unregisterDevice() async {
    if (_registeredToken == null) {
      _statusNotifier.setBackendRegistered(false);
      return;
    }
    final session = _ref.read(sessionProvider);
    if (!session.isAuthenticated || session.token == null) {
      _statusNotifier.setBackendRegistered(false);
      return;
    }
    await _unregisterFromBackend(
      authToken: session.token!,
      deviceToken: _registeredToken!,
    );
    _registeredToken = null;
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
      _statusNotifier.setBackendRegistered(false);
    }
  }

  Future<void> _registerWithBackend(String token) async {
    final session = _ref.read(sessionProvider);
    if (!session.isAuthenticated || session.token == null) {
      AppLogger.debug(
        'Skipping push registration until auth completes',
        tag: 'PushService',
      );
      _statusNotifier.setBackendRegistered(false);
      return;
    }
    try {
      _statusNotifier
        ..setRegistering(true)
        ..clearError();
      final api = createApiClient(token: session.token);
      await api.registerPushDevice(
        token: token,
        platform: _platform,
        deviceId: await _deviceId(),
        locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      );
      _registeredToken = token;
      _statusNotifier
        ..setBackendRegistered(true)
        ..clearError()
        ..setRegistering(false);
      AppLogger.info('Push token registered with backend', tag: 'PushService');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to register push token',
        tag: 'PushService',
        error: e,
        stackTrace: stack,
      );
      _statusNotifier
        ..setBackendRegistered(false)
        ..setRegistering(false)
        ..setError(e.toString());
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
      _statusNotifier.setBackendRegistered(false);
    } catch (e) {
      AppLogger.warning(
        'Failed to unregister push token',
        tag: 'PushService',
        error: e,
      );
      _statusNotifier.setError(e.toString());
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

class PushRegistrationState {
  const PushRegistrationState({
    this.settings,
    this.firebaseToken,
    this.backendRegistered = false,
    this.isRegistering = false,
    this.lastError,
  });

  final NotificationSettings? settings;
  final String? firebaseToken;
  final bool backendRegistered;
  final bool isRegistering;
  final String? lastError;

  bool get permissionGranted {
    final status = settings?.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  PushRegistrationState copyWith({
    NotificationSettings? settings,
    bool settingsSet = false,
    String? firebaseToken,
    bool firebaseTokenSet = false,
    bool? backendRegistered,
    bool? isRegistering,
    String? lastError,
    bool clearError = false,
  }) {
    return PushRegistrationState(
      settings: settingsSet ? settings : this.settings,
      firebaseToken:
          firebaseTokenSet ? firebaseToken : this.firebaseToken,
      backendRegistered: backendRegistered ?? this.backendRegistered,
      isRegistering: isRegistering ?? this.isRegistering,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class PushStatusNotifier extends StateNotifier<PushRegistrationState> {
  PushStatusNotifier() : super(const PushRegistrationState());

  void updateSettings(NotificationSettings settings) {
    state = state.copyWith(settings: settings, settingsSet: true);
  }

  void setFirebaseToken(String? token) {
    state = state.copyWith(
      firebaseToken: token,
      firebaseTokenSet: true,
    );
  }

  void setBackendRegistered(bool value) {
    state = state.copyWith(backendRegistered: value);
  }

  void setRegistering(bool value) {
    state = state.copyWith(isRegistering: value);
  }

  void setError(String? message) {
    state = state.copyWith(lastError: message);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
