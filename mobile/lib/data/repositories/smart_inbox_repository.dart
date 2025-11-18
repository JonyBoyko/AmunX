import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../presentation/providers/smart_inbox_provider.dart';
import '../api/api_client.dart';
import '../repositories/feed_repository.dart';

abstract class SmartInboxDataSource {
  Future<SmartInboxState> fetchSmartInbox({String? token});
  Future<SmartInboxState> fallbackFromEpisodes({String? token});
}

class SmartInboxRepository implements SmartInboxDataSource {
  SmartInboxRepository(this._ref);

  final Ref _ref;

  @override
  Future<SmartInboxState> fetchSmartInbox({String? token}) async {
    AppLogger.debug('Fetching smart inbox via API', tag: 'SmartInboxRepo');
    final apiClient = createApiClient(token: token);
    final payload = await apiClient.getSmartInbox();
    return SmartInboxState.fromJson(
      Map<String, dynamic>.from(payload as Map),
    );
  }

  @override
  Future<SmartInboxState> fallbackFromEpisodes({String? token}) async {
    final feedRepository = _ref.read(feedRepositoryProvider);
    final episodes = await feedRepository.getEpisodes(token: token);
    return SmartInboxState.fromEpisodes(episodes);
  }
}

final smartInboxRepositoryProvider = Provider<SmartInboxDataSource>((ref) {
  return SmartInboxRepository(ref);
});
