import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../presentation/providers/session_provider.dart';

class LiveRepository {
  LiveRepository(this.ref);

  final Ref ref;

  Future<List<Map<String, dynamic>>> fetchActiveRoomsRaw({
    int limit = 20,
  }) async {
    final token = ref.read(sessionProvider).token;
    final client = createApiClient(token: token);
    final response = await client.getLiveSessions(limit: limit);
    final sessions = response['sessions'] as List<dynamic>? ?? const [];
    return sessions
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  return LiveRepository(ref);
});
