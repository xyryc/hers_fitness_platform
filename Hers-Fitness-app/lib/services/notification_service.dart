import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/app_notification_model.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    if (token.trim().isEmpty) return;

    await _apiClient.post(
      ApiEndpoints.notificationDeviceTokens,
      body: {
        'token': token.trim(),
        'platform': platform.toUpperCase(),
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
    );
  }

  Future<void> unregisterDeviceToken({required String token}) async {
    if (token.trim().isEmpty) return;

    await _apiClient.deleteWithBody(
      ApiEndpoints.notificationDeviceTokens,
      body: {'token': token.trim()},
    );
  }

  Future<List<AppNotificationModel>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return _extractList(response)
        .whereType<Map>()
        .map((item) => AppNotificationModel.fromJson(_stringMap(item)))
        .toList();
  }

  Future<NotificationUnreadCountModel> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.notificationUnreadCount);
    return NotificationUnreadCountModel.fromJson(_extractObject(response));
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await _apiClient.patch(ApiEndpoints.notificationRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch(ApiEndpoints.notificationsReadAll);
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await _apiClient.delete(ApiEndpoints.notificationDelete(notificationId));
  }

  Future<void> deleteAllNotifications() async {
    await _apiClient.delete(ApiEndpoints.notificationsDeleteAll);
  }

  Future<void> sendTestPush() async {
    await _apiClient.post(ApiEndpoints.notificationTestPush);
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map<String, dynamic>) return const [];

    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      final dataMap = _stringMap(data);
      for (final key in const ['items', 'notifications', 'results']) {
        final value = dataMap[key];
        if (value is List) return value;
      }
    }

    for (final key in const ['items', 'notifications', 'results']) {
      final value = response[key];
      if (value is List) return value;
    }

    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map) return _stringMap(data);
      return response;
    }

    throw const ApiException('Invalid server response');
  }

  Map<String, dynamic> _stringMap(Map value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
