import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/notification_preferences_model.dart';

class NotificationPreferencesService {
  NotificationPreferencesService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// GET /api/notifications/preferences
  Future<NotificationPreferencesModel> getPreferences() async {
    final response = await _apiClient.get(ApiEndpoints.notificationPreferences);
    return NotificationPreferencesModel.fromJson(_asMap(response));
  }

  /// PATCH /api/notifications/preferences  — send only the changed field(s)
  Future<NotificationPreferencesModel> updatePreferences(
    Map<String, dynamic> fields,
  ) async {
    final response = await _apiClient.patch(
      ApiEndpoints.notificationPreferences,
      body: fields,
    );
    return NotificationPreferencesModel.fromJson(_asMap(response));
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    throw const ApiException('Invalid server response');
  }
}
