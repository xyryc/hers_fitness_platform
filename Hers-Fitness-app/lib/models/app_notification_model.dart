class AppNotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const <String, dynamic>{},
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = _object(json['data']);

    return AppNotificationModel(
      id: _readString(json, const ['id', 'notificationId']) ?? '',
      userId: _readString(json, const ['userId', 'user_id']) ?? '',
      type: (_readString(json, const ['type']) ?? '').toUpperCase(),
      title: _readString(json, const ['title']) ?? 'Notification',
      body: _readString(json, const ['body', 'message']) ?? '',
      data: payload ?? const <String, dynamic>{},
      readAt: _readDate(json, const ['readAt', 'read_at']),
      createdAt: _readDate(json, const ['createdAt', 'created_at']),
    );
  }

  AppNotificationModel copyWith({DateTime? readAt}) {
    return AppNotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationUnreadCountModel {
  final int unreadCount;

  const NotificationUnreadCountModel({required this.unreadCount});

  factory NotificationUnreadCountModel.fromJson(Map<String, dynamic> json) {
    return NotificationUnreadCountModel(
      unreadCount: _readInt(json, const ['unreadCount', 'unread_count']) ?? 0,
    );
  }
}

Map<String, dynamic>? _object(dynamic value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null || value is Map || value is Iterable) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }

  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return int.tryParse(value);
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return DateTime.tryParse(value);
}
