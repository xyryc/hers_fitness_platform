class HelpTicketModel {
  final String id;
  final String? senderUserId;
  final String title;
  final String body;
  final String status;
  final String? adminNote;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HelpTicketModel({
    required this.id,
    this.senderUserId,
    required this.title,
    required this.body,
    required this.status,
    this.adminNote,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory HelpTicketModel.fromJson(Map<String, dynamic> json) {
    // Support both wrapped { data: {...} } and unwrapped responses
    final d = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return HelpTicketModel(
      id: d['id']?.toString() ?? '',
      senderUserId: d['senderUserId']?.toString(),
      title: d['title']?.toString() ?? '',
      body: d['body']?.toString() ?? '',
      status: d['status']?.toString() ?? 'OPEN',
      adminNote: _str(d['adminNote']),
      resolvedAt: _date(d['resolvedAt']),
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return (s.isEmpty || s.toLowerCase() == 'null') ? null : s;
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Human-readable status label
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'IN_REVIEW':
        return 'In Review';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      case 'OPEN':
      default:
        return 'Open';
    }
  }
}
