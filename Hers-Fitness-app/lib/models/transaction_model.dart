class TransactionModel {
  final String id;
  final String? className;
  final String? trainerName;
  final String totalAmount;
  final String currency;
  final String? couponCode;
  final String? paymentMethod;
  final String status;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const TransactionModel({
    required this.id,
    this.className,
    this.trainerName,
    required this.totalAmount,
    required this.currency,
    this.couponCode,
    this.paymentMethod,
    required this.status,
    this.paidAt,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      className: _str(json['className']),
      trainerName: _str(json['trainerName']),
      totalAmount: json['totalAmount']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
      couponCode: _str(json['couponCode']),
      paymentMethod: _str(json['paymentMethod']),
      status: json['status']?.toString() ?? '',
      paidAt: _parseDate(json['paidAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return (s.isEmpty || s.toLowerCase() == 'null') ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
