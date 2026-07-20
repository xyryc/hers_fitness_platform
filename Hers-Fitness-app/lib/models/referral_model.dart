class ReferralModel {
  final String referralCode;
  final String referralLink;

  const ReferralModel({required this.referralCode, required this.referralLink});

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return ReferralModel(
      referralCode: data['referralCode']?.toString() ?? '',
      referralLink: data['referralLink']?.toString() ?? '',
    );
  }
}
