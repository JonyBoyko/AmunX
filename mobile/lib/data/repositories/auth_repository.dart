import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String?> requestMagicLink(String email) async {
    final response = await _apiClient.requestMagicLink({'email': email});
    return response['token_hint'] as String?;
  }

  Future<Map<String, dynamic>> verifyMagicLink(String token) async {
    final response = await _apiClient.verifyMagicLink({'token': token});
    return response;
  }

  Future<Map<String, dynamic>> devLogin(String email) async {
    return _apiClient.devLogin(email);
  }

  Future<User> getCurrentUser(String authToken) async {
    final authedClient = createApiClient(token: authToken);
    final profile = await authedClient.getCurrentUserProfile();
    final plan = profile['plan'] as String? ?? 'free';
    return User(
      id: profile['id'] as String,
      email: profile['email'] as String,
      isPro: plan.toLowerCase() == 'pro',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = createApiClient();
  return AuthRepository(apiClient);
});
