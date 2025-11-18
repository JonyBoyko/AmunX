import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/billing.dart';
import '../../data/repositories/billing_repository.dart';
import '../providers/billing_provider.dart';
import '../services/revenuecat_service.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(billingProductsProvider);
    final subscriptionAsync = ref.watch(billingSubscriptionProvider);
    final portalAsync = ref.watch(billingPortalProvider);
    final subscription =
        subscriptionAsync.maybeWhen(data: (sub) => sub, orElse: () => null);
    final portalInfo =
        portalAsync.maybeWhen(data: (info) => info, orElse: () => null);
    final isPortalLoading = portalAsync.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandPrimary,
          onRefresh: () async {
            ref.invalidate(billingProductsProvider);
            ref.invalidate(billingSubscriptionProvider);
            ref.invalidate(billingPortalProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const _PaywallHeader(),
              const SizedBox(height: AppTheme.spaceLg),
              subscriptionAsync.when(
                data: (sub) => _PlanStatus(
                  subscription: sub,
                  portalInfo: portalInfo,
                  isPortalLoading: isPortalLoading,
                  onManagePortal: () =>
                      _openStripePortal(context, ref, cachedPortal: portalInfo),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              productsAsync.when(
                data: (products) => _ProductSections(
                  products: products,
                  subscription: subscription,
                  portalInfo: portalInfo,
                  portalLoading: isPortalLoading,
                  onRevenueCatPurchase: (product) =>
                      _purchaseWithRevenueCat(context, ref, product),
                  onStripeManage: () =>
                      _openStripePortal(context, ref, cachedPortal: portalInfo),
                  onMonoPayCheckout: (product) =>
                      _startMonoPayCheckout(context, ref, product),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorCard(
                  message: 'Не вдалося отримати плани: $error',
                  onRetry: () {
                    ref.invalidate(billingProductsProvider);
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              FilledButton.tonal(
                onPressed: () => _restorePurchases(context, ref),
                child: const Text('Відновити покупки'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseWithRevenueCat(
    BuildContext context,
    WidgetRef ref,
    BillingProduct product,
  ) async {
    final service = ref.read(revenueCatServiceProvider);
    try {
      await service.purchaseProduct(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Підписку оформлено успішно')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'RevenueCat purchase failed',
        tag: 'Paywall',
        error: e,
        stackTrace: stack,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка оформлення: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final service = ref.read(revenueCatServiceProvider);
    try {
      await service.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Покупки відновлено')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Restore purchases failed',
        tag: 'Paywall',
        error: e,
        stackTrace: stack,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка відновлення: $e')),
        );
      }
    }
  }

  Future<void> _openStripePortal(
    BuildContext context,
    WidgetRef ref, {
    BillingPortalInfo? cachedPortal,
  }) async {
    try {
      final cachedUrl = cachedPortal?.stripePortalUrl;
      final portal = cachedUrl?.isNotEmpty == true
          ? cachedPortal!
          : await ref.read(billingRepositoryProvider).fetchPortal();
      final url = portal.stripePortalUrl;
      if (url == null || url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Статус Stripe поки недоступний')),
          );
        }
        return;
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити Stripe')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to open Stripe portal',
        tag: 'Paywall',
        error: e,
        stackTrace: stack,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка Stripe: $e')),
        );
      }
    }
  }

  Future<void> _startMonoPayCheckout(
    BuildContext context,
    WidgetRef ref,
    BillingProduct product,
  ) async {
    try {
      final url =
          await ref.read(billingRepositoryProvider).createMonoPayCheckout(
                productCode: product.code,
              );
      if (url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MonoPay тимчасово недоступний')),
          );
        }
        return;
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити MonoPay')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to start MonoPay checkout',
        tag: 'Paywall',
        error: e,
        stackTrace: stack,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка MonoPay: $e')),
        );
      }
    }
  }
}

class _PlanStatus extends StatelessWidget {
  const _PlanStatus({
    required this.subscription,
    this.portalInfo,
    this.isPortalLoading = false,
    this.onManagePortal,
  });

  final BillingSubscription subscription;
  final BillingPortalInfo? portalInfo;
  final bool isPortalLoading;
  final VoidCallback? onManagePortal;

  @override
  Widget build(BuildContext context) {
    final planName =
        subscription.plan.isEmpty ? 'FREE' : subscription.plan.toUpperCase();
    final expiry = subscription.periodEnd;
    final expiryText = expiry == null
        ? null
        : DateFormat.yMMMd().format(expiry.toLocal());
    final providerKey = subscription.provider?.toLowerCase();
    final providerLabel = _providerLabel(subscription.provider);
    final manageStripe =
        providerKey == 'stripe' &&
        (portalInfo?.stripePortalUrl?.isNotEmpty ?? false) &&
        onManagePortal != null;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Твій план',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            planName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          if (expiryText != null) ...[
            const SizedBox(height: 4),
            Text(
              'Чинний до $expiryText',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          if (providerLabel.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Провайдер: $providerLabel',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          if (manageStripe) ...[
            const SizedBox(height: AppTheme.spaceSm),
            FilledButton.tonal(
              onPressed: isPortalLoading ? null : onManagePortal,
              child: isPortalLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Відкрити Stripe портал'),
            ),
          ],
          if (!manageStripe && providerKey == 'monopay') ...[
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'MonoPay планами поки керує саппорт.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

String _providerLabel(String? provider) {
  switch (provider?.toLowerCase()) {
    case 'stripe':
      return 'Stripe';
    case 'revenuecat':
      return 'App Store / Google Play';
    case 'monopay':
      return 'MonoPay';
    case null:
      return '';
    case '':
      return '';
    default:
      return provider!;
  }
}
class _ProductSections extends StatelessWidget {
  const _ProductSections({
    required this.products,
    required this.subscription,
    required this.portalInfo,
    required this.portalLoading,
    required this.onRevenueCatPurchase,
    required this.onStripeManage,
    required this.onMonoPayCheckout,
  });

  final List<BillingProduct> products;
  final BillingSubscription? subscription;
  final BillingPortalInfo? portalInfo;
  final bool portalLoading;
  final void Function(BillingProduct) onRevenueCatPurchase;
  final VoidCallback onStripeManage;
  final void Function(BillingProduct) onMonoPayCheckout;

  @override
  Widget build(BuildContext context) {
    final rcProducts = products.where((p) => p.isRevenueCat).toList();
    final stripeProducts = products.where((p) => p.isStripe).toList();
    final monoProducts = products.where((p) => p.isMonoPay).toList();
    final activeCode = subscription?.productCode;
    final activeProvider = subscription?.provider?.toLowerCase();
    final hasStripePortal = portalInfo?.stripePortalUrl?.isNotEmpty ?? false;

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: const Text(
          'Плани ще не підʼїхали. Спробуйте оновити вікно.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rcProducts.isNotEmpty) ...[
          const Text(
            'App Store / Google Play',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...rcProducts.map((product) {
            final isActive =
                activeCode != null &&
                activeCode == product.code &&
                activeProvider == 'revenuecat';
            return _BillingProductTile(
              product: product,
              actionLabel:
                  isActive ? 'Активно в магазині' : 'Купити через магазин',
              onPressed:
                  isActive ? null : () => onRevenueCatPurchase(product),
              isActive: isActive,
              helperText: isActive
                  ? 'Підпискою керує App Store / Google Play'
                  : 'Транзакція піде через App Store / Google Play',
            );
          }),
          const SizedBox(height: AppTheme.spaceLg),
        ],
        if (stripeProducts.isNotEmpty) ...[
          const Text(
            'Stripe (картка)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...stripeProducts.map((product) {
            final isActive =
                activeCode != null &&
                activeCode == product.code &&
                activeProvider == 'stripe';
            final hasPortal = hasStripePortal;
            final disabled = !hasPortal || portalLoading;
            return _BillingProductTile(
              product: product,
              actionLabel: isActive
                  ? 'Керувати у Stripe'
                  : 'Відкрити Stripe портал',
              onPressed: disabled ? null : onStripeManage,
              isActive: isActive,
              helperText: hasPortal
                  ? 'Відкриє Stripe Customer Portal'
                  : 'Портал зараз недоступний',
              isLoading: portalLoading && hasPortal,
            );
          }),
          const SizedBox(height: AppTheme.spaceLg),
        ],
        if (monoProducts.isNotEmpty) ...[
          const Text(
            'MonoPay (Україна)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...monoProducts.map((product) {
            final isActive =
                activeCode != null &&
                activeCode == product.code &&
                activeProvider == 'monopay';
            return _BillingProductTile(
              product: product,
              actionLabel:
                  isActive ? 'Активний MonoPay' : 'MonoPay checkout',
              onPressed:
                  isActive ? null : () => onMonoPayCheckout(product),
              isActive: isActive,
              helperText:
                  isActive ? 'Зміни поки через саппорт' : null,
            );
          }),
        ],
      ],
    );
  }
}
class _BillingProductTile extends StatelessWidget {
  const _BillingProductTile({
    required this.product,
    required this.actionLabel,
    required this.onPressed,
    this.isActive = false,
    this.helperText,
    this.isLoading = false,
  });

  final BillingProduct product;
  final String actionLabel;
  final VoidCallback? onPressed;
  final bool isActive;
  final String? helperText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.description.isEmpty
                ? 'Доступ до всього Moweton Pro.'
                : product.description,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: AppTheme.spaceSm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: AppTheme.brandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (helperText != null && helperText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceSm),
          FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppTheme.stateDanger),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextButton(
            onPressed: onRetry,
            child: const Text('Спробувати ще раз'),
          ),
        ],
      ),
    );
  }
}

class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.workspace_premium, size: 64, color: AppTheme.brandAccent),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Moweton Pro',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'AI-помічник для голосових кімнат, подій і дайджестів.',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


