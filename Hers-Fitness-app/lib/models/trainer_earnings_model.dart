class TrainerEarningsModel {
  final String period;
  final int? year;
  final double totalEarnings;
  final List<TrainerEarningsItem> data;

  const TrainerEarningsModel({
    required this.period,
    this.year,
    required this.totalEarnings,
    required this.data,
  });

  factory TrainerEarningsModel.fromJson(Map<String, dynamic> json) {
    final d = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawList = d['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(TrainerEarningsItem.fromJson)
              .toList()
        : <TrainerEarningsItem>[];

    return TrainerEarningsModel(
      period: d['period']?.toString() ?? 'monthly',
      year: _parseInt(d['year']),
      totalEarnings: _parseDouble(d['totalEarnings']) ?? 0,
      data: items,
    );
  }

  /// Maximum earnings value across all items; used to normalise bar heights.
  double get maxEarnings {
    if (data.isEmpty) return 1;
    final m = data.fold<double>(
      0,
      (prev, e) => e.earnings > prev ? e.earnings : prev,
    );
    return m == 0 ? 1 : m;
  }

  static TrainerEarningsModel empty(String period) =>
      TrainerEarningsModel(period: period, totalEarnings: 0, data: const []);

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.round();
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}

class TrainerEarningsItem {
  final String label;
  final String key;
  final double earnings;

  const TrainerEarningsItem({
    required this.label,
    required this.key,
    required this.earnings,
  });

  factory TrainerEarningsItem.fromJson(Map<String, dynamic> json) {
    return TrainerEarningsItem(
      label: json['label']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      earnings: double.tryParse(json['earnings']?.toString() ?? '0') ?? 0,
    );
  }
}
