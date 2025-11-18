import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/billing.dart';
import '../../presentation/providers/session_provider.dart';

class BillingRepository {
  BillingRepository(this._ref);

  final Ref _ref;

  Future<List<BillingProduct>> fetchProducts() async {
    final token = _ref.read(sessionProvider).token;
    final client = createApiClient(token: token);
    final response = await client.getBillingProducts();
    final products = response['products'] as List<dynamic>? ?? const [];
    return products
        .whereType<Map<String, dynamic>>()
        .map(BillingProduct.fromJson)
        .toList();
  }

  Future<BillingSubscription> fetchSubscription() async {
    final token = _ref.read(sessionProvider).token;
    final client = createApiClient(token: token);
    final response = await client.getBillingSubscription();
    return BillingSubscription.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<BillingPortalInfo> fetchPortal() async {
    final token = _ref.read(sessionProvider).token;
    final client = createApiClient(token: token);
    final response = await client.getBillingPortal();
    return BillingPortalInfo.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<String> createMonoPayCheckout({
    required String productCode,
    String? successUrl,
  }) async {
    final token = _ref.read(sessionProvider).token;
    final client = createApiClient(token: token);
    final response = await client.createMonoPayCheckout(
      productCode: productCode,
      successUrl: successUrl,
    );
    return (response['checkout_url'] as String?) ?? '';
  }
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref);
});
