import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/member_booking_model.dart';
import 'package:fitness/models/member_next_workout_model.dart';

class MemberBookingService {
  MemberBookingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<MemberBookingModel>> getBookedClasses() async {
    final response = await _apiClient.get(ApiEndpoints.memberBookedClasses);
    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(MemberBookingModel.fromJson)
        .toList();
  }

  Future<MemberBookingModel?> getNextBooking() async {
    final response = await _apiClient.get(ApiEndpoints.memberNextBooking);
    final data = _extractObjectOrNull(response);
    return data == null ? null : MemberBookingModel.fromJson(data);
  }

  Future<List<MemberNextWorkoutModel>> getNextWorkouts({int limit = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.memberNextWorkouts,
      queryParameters: {'limit': limit},
    );
    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(MemberNextWorkoutModel.fromJson)
        .toList();
  }

  Future<List<MemberBookingModel>> getBookings() async {
    final response = await _apiClient.get(ApiEndpoints.memberBookings);
    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(MemberBookingModel.fromJson)
        .toList();
  }

  Future<void> requestReschedule({
    required String bookingId,
    required String newDate,
    required String newStartTime,
  }) async {
    await _apiClient.post(
      ApiEndpoints.memberBookingReschedule(bookingId),
      body: {'newDate': newDate, 'newStartTime': newStartTime},
    );
  }

  Future<void> acceptReschedule(String bookingId) async {
    await _apiClient.patch(
      ApiEndpoints.memberBookingRescheduleAccept(bookingId),
    );
  }

  Future<void> completeBooking(String bookingId) async {
    await _apiClient.patch(ApiEndpoints.memberBookingComplete(bookingId));
  }

  Future<void> checkIn(String bookingId) async {
    await _apiClient.patch(ApiEndpoints.memberBookingCheckIn(bookingId));
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['items', 'bookings', 'classes', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    for (final key in const ['items', 'bookings', 'classes', 'results']) {
      final value = response[key];
      if (value is List) return value;
    }

    return const [];
  }

  Map<String, dynamic>? _extractObjectOrNull(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;

    return null;
  }
}
