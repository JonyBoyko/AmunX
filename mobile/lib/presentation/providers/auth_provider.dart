import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/repositories/auth_repository.dart';
import 'session_provider.dart';

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authRepository, this._sessionNotifier)
      : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;
  final SessionNotifier _sessionNotifier;

  Future<String?> requestMagicLink(String email) async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('requestMagicLink start for $email', tag: 'AuthProvider');
      final tokenHint = await _authRepository.requestMagicLink(email);
      state = const AsyncValue.data(null);
      return tokenHint;
    } catch (e, stackTrace) {
      AppLogger.error(
        'requestMagicLink failed for $email',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> verifyMagicLink(String token) async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('verifyMagicLink start', tag: 'AuthProvider');
      final response = await _authRepository.verifyMagicLink(token);
      final accessToken = response['access_token'] as String;
      await _sessionNotifier.setToken(accessToken);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'verifyMagicLink failed',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> devLogin(String email) async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('devLogin start for $email', tag: 'AuthProvider');
      final response = await _authRepository.devLogin(email);
      final accessToken = response['access_token'] as String;
      await _sessionNotifier.setToken(accessToken);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'devLogin failed for $email',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final sessionNotifier = ref.read(sessionProvider.notifier);
    return AuthNotifier(authRepository, sessionNotifier);
  },
);
