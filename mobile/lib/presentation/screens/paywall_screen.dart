import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandPrimary,
          onRefresh: () async {
            ref.invalidate(billingProductsProvider);
            ref.invalidate(billingSubscriptionProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const _PaywallHeader(),
              const SizedBox(height: AppTheme.spaceLg),
              subscriptionAsync.when(
                data: (sub) => _PlanStatus(subscription: sub),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              productsAsync.when(
                data: (products) => _ProductSections(
                  products: products,
                  onRevenueCatPurchase: (product) => _purchaseWithRevenueCat(context, ref, product),
                  onStripeManage: () => _openStripePortal(context, ref),
                  onMonoPayCheckout: (product) => _startMonoPayCheckout(context, ref, product),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorCard(
                  message: 'Не вдалося завантажити плани: $error',
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
          const SnackBar(content: Text('Успішно оформлено підписку!')),
        );
      }
    } catch (e, stack) {
      AppLogger.error('RevenueCat purchase failed', tag: 'Paywall', error: e, stackTrace: stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка підписки: $e')),
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
      AppLogger.error('Restore purchases failed', tag: 'Paywall', error: e, stackTrace: stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка відновлення: $e')),
        );
      }
    }
  }

  Future<void> _openStripePortal(BuildContext context, WidgetRef ref) async {
    try {
      final info = await ref.read(billingRepositoryProvider).fetchPortal();
      final url = info.stripePortalUrl;
      if (url == null || url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Портал Stripe недоступний для акаунта')),
          );
        }
        return;
      }
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалось відкрити Stripe портал')),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to open Stripe portal', tag: 'Paywall', error: e, stackTrace: stack);
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
      final url = await ref.read(billingRepositoryProvider).createMonoPayCheckout(
            productCode: product.code,
            successUrl: null,
          );
      if (url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MonoPay недоступний')),
          );
        }
        return;
    }
}

  Future<void> _startMonoPayCheckout(
    BuildContext context,
    WidgetRef ref,
    BillingProduct product,
  ) async {
    try {
      final url = await ref.read(billingRepositoryProvider).createMonoPayCheckout(
            productCode: product.code,
          );
      if (url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MonoPay ��������� �����������')),
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
          const SnackBar(content: Text('�� ������� ������� MonoPay')),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to start MonoPay checkout', tag: 'Paywall', error: e, stackTrace: stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('������� MonoPay: ')),
        );
      }
    }
  }
class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.subscription});

  final BillingSubscription subscription;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Ваш план: ${subscription.plan.toUpperCase()}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subscription.periodEnd != null)
            Text(
              'Активно до ${subscription.periodEnd}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _ProductSections extends StatelessWidget {
  const _ProductSections({
    required this.products,
    required this.onRevenueCatPurchase,
    required this.onStripeManage,
    required this.onMonoPayCheckout,
  });

  final List<BillingProduct> products;
  final void Function(BillingProduct) onRevenueCatPurchase;
  final VoidCallback onStripeManage;
  final void Function(BillingProduct) onMonoPayCheckout;

  @override
  Widget build(BuildContext context) {
    final rcProducts = products.where((p) => p.isRevenueCat).toList();
    final stripeProducts = products.where((p) => p.isStripe).toList();
    final monoPayProducts = products.where((p) => p.isMonoPay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rcProducts.isNotEmpty) ...[
          const Text(
            'Підписка через App Store / Google Play',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...rcProducts.map(
            (product) => _BillingProductTile(
              product: product,
              actionLabel: 'Підписатись',
              onPressed: () => onRevenueCatPurchase(product),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
        ],
        if (stripeProducts.isNotEmpty) ...[
          const Text(
            'Підписка карткою (Stripe)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...stripeProducts.map(
            (product) => _BillingProductTile(
              product: product,
              actionLabel: 'Оплатити карткою',
              onPressed: onStripeManage,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
        ],
        if (monoPayProducts.isNotEmpty) ...[
          const Text(
            'Оплата MonoPay (Україна)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...monoPayProducts.map(
            (product) => _BillingProductTile(
              product: product,
              actionLabel: 'MonoPay',
              onPressed: () => onMonoPayCheckout(product),
            ),
          ),
        ],
        if (rcProducts.isEmpty && stripeProducts.isEmpty && monoPayProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Text(
              'Плани поки недоступні. Спробуйте пізніше.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _BillingProductTile extends StatelessWidget {
  const _BillingProductTile({
    required this.product,
    required this.actionLabel,
    required this.onPressed,
  });

  final BillingProduct product;
  final String actionLabel;
  final VoidCallback onPressed;

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
            product.description.isEmpty ? 'Повний доступ до преміум функцій' : product.description,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            product.formattedPrice,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          FilledButton(
            onPressed: onPressed,
            child: Text(actionLabel),
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
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
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
    return Column(
      children: const [
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
          'AI-посібник для ваших голосових розмов',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

