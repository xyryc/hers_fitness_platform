import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/trainer_schedule_model.dart';

class TrainerScheduleService {
  TrainerScheduleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<TrainerScheduleResponse> getSchedule({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;

    final response = await _apiClient.get(
      ApiEndpoints.trainerSchedule,
      queryParameters: params.isEmpty ? null : params,
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid schedule response');
    }

    return TrainerScheduleResponse.fromJson(response);
  }

  Future<void> checkIn(String bookingId) async {
    await _apiClient.patch(ApiEndpoints.trainerBookingCheckIn(bookingId));
  }

  Future<void> markComplete(String bookingId) async {
    await _apiClient.patch(ApiEndpoints.trainerBookingComplete(bookingId));
  }

  Future<void> requestReschedule(
    String bookingId, {
    required String scheduledDate,
    required String startTime,
  }) async {
    await _apiClient.post(
      ApiEndpoints.trainerBookingReschedule(bookingId),
      body: {'scheduledDate': scheduledDate, 'startTime': startTime},
    );
  }

  Future<void> acceptReschedule(String bookingId) async {
    await _apiClient.patch(
      ApiEndpoints.trainerBookingRescheduleAccept(bookingId),
    );
  }
}
