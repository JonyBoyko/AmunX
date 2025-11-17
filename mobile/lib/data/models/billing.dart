class BillingProduct {
  final String id;
  final String code;
  final String name;
  final String description;
  final String provider;
  final String externalId;
  final String currency;
  final int amountCents;
  final String interval;

  const BillingProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.provider,
    required this.externalId,
    required this.currency,
    required this.amountCents,
    required this.interval,
  });

  factory BillingProduct.fromJson(Map<String, dynamic> json) {
    return BillingProduct(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      externalId: json['external_id'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      amountCents: json['amount_cents'] as int? ?? 0,
      interval: json['interval'] as String? ?? 'month',
    );
  }

  String get formattedPrice {
    final amount = (amountCents / 100).toStringAsFixed(2);
    return '$currency $amount / ${intervalLabel.toLowerCase()}';
  }

  String get intervalLabel {
    switch (interval.toLowerCase()) {
      case 'year':
        return 'Year';
      case 'month':
      default:
        return 'Month';
    }
  }

  bool get isRevenueCat => provider == 'revenuecat';
  bool get isStripe => provider == 'stripe';
  bool get isMonoPay => provider == 'monopay';
}

class BillingSubscription {
  final String plan;
  final String? productCode;
  final String? provider;
  final DateTime? periodEnd;

  const BillingSubscription({
    required this.plan,
    this.productCode,
    this.provider,
    this.periodEnd,
  });

  factory BillingSubscription.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    DateTime? periodEnd;
    String? productCode;
    String? provider;
    if (subscription != null) {
      final rawTime = subscription['current_period_end'] as String?;
      periodEnd = rawTime == null ? null : DateTime.tryParse(rawTime);
      productCode = subscription['product_code'] as String?;
      provider = subscription['provider'] as String?;
    }
    return BillingSubscription(
      plan: json['plan'] as String? ?? 'free',
      productCode: productCode,
      provider: provider,
      periodEnd: periodEnd,
    );
  }
}

class BillingPortalInfo {
  final String? stripePortalUrl;
  final String? revenueCatUserId;

  const BillingPortalInfo({
    this.stripePortalUrl,
    this.revenueCatUserId,
  });

  factory BillingPortalInfo.fromJson(Map<String, dynamic> json) {
    return BillingPortalInfo(
      stripePortalUrl: json['stripe_customer_portal'] as String?,
      revenueCatUserId: json['revenuecat_app_user_id'] as String?,
    );
  }
}

