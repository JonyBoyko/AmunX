import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/billing.dart';
import '../providers/billing_provider.dart';
import '../providers/session_provider.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService(ref);
});

final revenueCatBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(revenueCatServiceProvider).bootstrap();
});

class RevenueCatService {
  RevenueCatService(this._ref) {
    _ref.listen<SessionState>(
      sessionProvider,
      _handleSessionState,
      fireImmediately: true,
    );
  }

  final Ref _ref;
  bool _configured = false;

  Future<void> bootstrap() async {
    if (_configured) {
      return;
    }
    final apiKey = _platformApiKey();
    if (apiKey == null || apiKey.contains('YOUR_')) {
      AppLogger.warning('RevenueCat API key missing, skipping setup', tag: 'RevenueCat');
      return;
    }
    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = _ref.read(sessionProvider).user?.id;
    await Purchases.configure(configuration);
    _configured = true;
    AppLogger.info('RevenueCat configured', tag: 'RevenueCat');
  }

  Future<void> restorePurchases() async {
    if (!_configured) {
      await bootstrap();
    }
    if (!_configured) {
      return;
    }
    await Purchases.restorePurchases();
    _ref.invalidate(billingSubscriptionProvider);
  }

  Future<void> purchaseProduct(BillingProduct product) async {
    if (!_configured) {
      await bootstrap();
    }
    if (!_configured) {
      throw StateError('RevenueCat not configured');
    }
    final offerings = await Purchases.getOfferings();
    final package = _findPackageForProduct(offerings, product);
    if (package == null) {
      throw StateError('Product ${product.code} not available in RevenueCat');
    }
    AppLogger.info('Purchasing ${product.code}', tag: 'RevenueCat');
    await Purchases.purchasePackage(package);
    _ref.invalidate(billingSubscriptionProvider);
  }

  void _handleSessionState(SessionState? previous, SessionState next) {
    if (!_configured) {
      return;
    }
    if (next.isAuthenticated && next.user != null) {
      Purchases.logIn(next.user!.id).then(
        (_) => AppLogger.debug('RevenueCat logged in ${next.user!.id}', tag: 'RevenueCat'),
        onError: (e, stack) => AppLogger.error('RevenueCat login failed', tag: 'RevenueCat', error: e, stackTrace: stack),
      );
    } else if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
      Purchases.logOut().catchError((e, stack) {
        AppLogger.error('RevenueCat logout failed', tag: 'RevenueCat', error: e, stackTrace: stack);
      });
    }
  }

  String? _platformApiKey() {
    if (Platform.isIOS) {
      return AppConfig.revenueCatApiKeyIOS;
    }
    return AppConfig.revenueCatApiKeyAndroid;
  }

  Package? _findPackageForProduct(Offerings offerings, BillingProduct product) {
    final current = offerings.current;
    if (current == null) {
      return null;
    }
    for (final pkg in current.availablePackages) {
      if (pkg.identifier == product.code ||
          pkg.storeProduct.identifier == product.code ||
          pkg.storeProduct.sku == product.code ||
          pkg.storeProduct.identifier == product.externalId ||
          pkg.storeProduct.sku == product.externalId) {
        return pkg;
      }
    }
    for (final offering in offerings.all.values) {
      for (final pkg in offering.availablePackages) {
        if (pkg.identifier == product.code ||
            pkg.storeProduct.identifier == product.code ||
            pkg.storeProduct.sku == product.code ||
            pkg.storeProduct.identifier == product.externalId ||
            pkg.storeProduct.sku == product.externalId) {
          return pkg;
        }
      }
    }
    return null;
  }
}

