import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/repositories/auth_repository.dart';
import 'session_provider.dart';

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authRepository, this._sessionNotifier)
      : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;
  final SessionNotifier _sessionNotifier;

  Future<void> requestMagicLink(String email) async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('requestMagicLink start for $email', tag: 'AuthProvider');
      await _authRepository.requestMagicLink(email);
      AppLogger.info('requestMagicLink success for $email', tag: 'AuthProvider');
      state = const AsyncValue.data(null);
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
      final authToken = await _authRepository.verifyMagicLink(token);
      AppLogger.info('verifyMagicLink success, storing token', tag: 'AuthProvider');
      await _sessionNotifier.setToken(authToken);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final sessionNotifier = ref.read(sessionProvider.notifier);
    return AuthNotifier(authRepository, sessionNotifier);
  },
);

