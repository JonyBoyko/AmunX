import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> requestMagicLink(String email) async {
    await _apiClient.requestMagicLink({'email': email});
  }

  Future<String> verifyMagicLink(String token) async {
    final response = await _apiClient.verifyMagicLink({'token': token});
    return response['token'] as String;
  }

  Future<User> getCurrentUser(String authToken) async {
    // TODO: Implement get current user endpoint
    // For now, return mock user
    return const User(
      id: '1',
      email: 'user@amunx.app',
      isPro: false,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = createApiClient();
  return AuthRepository(apiClient);
});

