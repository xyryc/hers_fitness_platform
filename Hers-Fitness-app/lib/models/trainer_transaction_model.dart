class TrainerTransactionModel {
  final String id;
  final String? className;
  final String? memberName;
  final String amount;
  final String currency;
  final String status;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const TrainerTransactionModel({
    required this.id,
    this.className,
    this.memberName,
    required this.amount,
    required this.currency,
    required this.status,
    this.paidAt,
    this.createdAt,
  });

  factory TrainerTransactionModel.fromJson(Map<String, dynamic> json) {
    return TrainerTransactionModel(
      id: json['id']?.toString() ?? '',
      className: _str(json['className']),
      memberName: _str(json['memberName']),
      amount: json['amount']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
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

  /// True when the trainer has been paid
  bool get isPaid => status.toUpperCase() == 'PAID';

  /// Human-readable formatted amount, e.g. "USD 45.00"
  String get displayAmount =>
      '$currency ${double.tryParse(amount)?.toStringAsFixed(2) ?? amount}';
}
