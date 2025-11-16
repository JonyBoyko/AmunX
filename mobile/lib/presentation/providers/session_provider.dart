import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/logging/app_logger.dart';

class SessionState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final User? user;

  const SessionState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.token,
    this.user,
  });

  SessionState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    User? user,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._authRepository) : super(const SessionState()) {
    hydrate();
  }

  final AuthRepository _authRepository;

  Future<void> hydrate() async {
    AppLogger.info('Starting session hydration', tag: 'Session');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      AppLogger.info('Token found: ${token != null}', tag: 'Session');

      if (token != null) {
        try {
          AppLogger.info('Fetching user data', tag: 'Session');
          final user = await _authRepository.getCurrentUser(token);
          state = SessionState(
            isLoading: false,
            isAuthenticated: true,
            token: token,
            user: user,
          );
          AppLogger.info('User authenticated: ${user.email}', tag: 'Session');
        } catch (e, stackTrace) {
          AppLogger.error('Failed to get user', tag: 'Session', error: e, stackTrace: stackTrace);
          // Token invalid, clear it
          await prefs.remove('auth_token');
          state = const SessionState(isLoading: false);
        }
      } else {
        AppLogger.info('No token found, user not authenticated', tag: 'Session');
        state = const SessionState(isLoading: false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Session hydration failed', tag: 'Session', error: e, stackTrace: stackTrace);
      state = const SessionState(isLoading: false);
    }
  }

  Future<void> setToken(String token) async {
    AppLogger.info('Persisting auth token', tag: 'Session');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    try {
      AppLogger.info('Fetching user after token set', tag: 'Session');
      final user = await _authRepository.getCurrentUser(token);
      state = SessionState(
        isLoading: false,
        isAuthenticated: true,
        token: token,
        user: user,
      );
      AppLogger.info('Session authenticated: ${user.email}', tag: 'Session');
    } catch (e) {
      AppLogger.error('Failed to fetch user after setToken', tag: 'Session', error: e);
      state = const SessionState(isLoading: false);
    }
  }

  Future<void> clearSession() async {
    AppLogger.info('Clearing session', tag: 'Session');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const SessionState(isLoading: false);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return SessionNotifier(authRepository);
  },
);

