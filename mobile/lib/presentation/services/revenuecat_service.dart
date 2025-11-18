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
        throw e;
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
    bool matchesPackage(Package pkg) {
      final targets = <String>{
        product.code,
        if (product.externalId.isNotEmpty) product.externalId,
      };
      return targets.contains(pkg.identifier) ||
          targets.contains(pkg.storeProduct.identifier);
    }

    Package? searchOffering(Offering offering) {
      for (final pkg in offering.availablePackages) {
        if (matchesPackage(pkg)) {
          return pkg;
        }
      }
      return null;
    }

    final current = offerings.current;
    if (current != null) {
      final match = searchOffering(current);
      if (match != null) {
        return match;
      }
    }
    for (final offering in offerings.all.values) {
      final match = searchOffering(offering);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}
