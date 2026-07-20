class PayoutStatusModel {
  final String? stripeConnectAccountId;
  final bool onboardingComplete;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final bool payoutReady;
  final String? updatedAt;

  // Only present in the onboarding-link response
  final String? onboardingUrl;
  final String? expiresAt;

  const PayoutStatusModel({
    this.stripeConnectAccountId,
    required this.onboardingComplete,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.payoutReady,
    this.updatedAt,
    this.onboardingUrl,
    this.expiresAt,
  });

  factory PayoutStatusModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return PayoutStatusModel(
      stripeConnectAccountId: data['stripeConnectAccountId'] as String?,
      onboardingComplete: _bool(data['onboardingComplete']),
      chargesEnabled: _bool(data['chargesEnabled']),
      payoutsEnabled: _bool(data['payoutsEnabled']),
      detailsSubmitted: _bool(data['detailsSubmitted']),
      payoutReady: _bool(data['payoutReady']),
      updatedAt: data['updatedAt'] as String?,
      onboardingUrl: data['onboardingUrl'] as String?,
      expiresAt: data['expiresAt'] as String?,
    );
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
