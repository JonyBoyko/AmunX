import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/billing.dart';
import '../../data/repositories/billing_repository.dart';

final billingProductsProvider = FutureProvider.autoDispose<List<BillingProduct>>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  try {
    final products = await repository.fetchProducts();
    return products;
  } catch (e, stack) {
    AppLogger.error('Failed to load billing products', tag: 'Billing', error: e, stackTrace: stack);
    rethrow;
  }
});

final billingSubscriptionProvider = FutureProvider.autoDispose<BillingSubscription>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  try {
    final subscription = await repository.fetchSubscription();
    return subscription;
  } catch (e, stack) {
    AppLogger.error('Failed to load subscription', tag: 'Billing', error: e, stackTrace: stack);
    rethrow;
  }
});

final billingPortalProvider = FutureProvider.autoDispose<BillingPortalInfo>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  try {
    final portal = await repository.fetchPortal();
    return portal;
  } catch (e, stack) {
    AppLogger.error('Failed to load billing portal', tag: 'Billing', error: e, stackTrace: stack);
    rethrow;
  }
});

