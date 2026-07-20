import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/trainer_availability_model.dart';
import 'package:fitness/models/trainer_class_model.dart';
import 'package:fitness/models/trainer_earnings_model.dart';
import 'package:fitness/models/trainer_top_class_model.dart';

class TrainerClassService {
  TrainerClassService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<TrainerClassModel>> getClasses({
    bool includeCompleted = false,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerClasses,
      queryParameters: includeCompleted ? {'includeCompleted': 'true'} : null,
    );
    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(TrainerClassModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _apiClient.get(ApiEndpoints.trainerDashboardStats);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return const {};
  }

  Future<TrainerClassModel?> getNextClass() async {
    final response = await _apiClient.get(ApiEndpoints.trainerNextClass);
    if (response is! Map<String, dynamic>) return null;
    final data = response['data'];
    if (data == null) return null;
    if (data is Map<String, dynamic>) return TrainerClassModel.fromJson(data);
    return null;
  }

  Future<List<TrainerClassModel>> getTodayClasses(String date) async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerClasses,
      queryParameters: {'date': date},
    );
    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(TrainerClassModel.fromJson)
        .toList();
  }

  Future<TrainerClassModel> getClassById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.trainerClassById(id));
    final data = _extractObjectOrNull(response);
    if (data == null) {
      throw const ApiException('Class was not found.');
    }

    return TrainerClassModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getClassDetails(String id) async {
    final response = await _apiClient.get(ApiEndpoints.trainerClassById(id));
    final data = _extractObjectOrNull(response);
    if (data == null) {
      throw const ApiException('Class was not found.');
    }

    return data;
  }

  Future<TrainerAvailabilityResponse> getTrainerAvailability({
    required String trainerUserId,
    required String month,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerAvailability(trainerUserId),
      queryParameters: {'month': month},
    );
    final data = _extractObjectOrNull(response);
    if (data == null) {
      throw const ApiException('Availability was not found.');
    }

    return TrainerAvailabilityResponse.fromJson(data);
  }

  Future<TrainerClassModel?> createClass(TrainerClassPayload payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.trainerClasses,
      body: payload.toJson(),
    );
    final data = _extractObjectOrNull(response);
    return data == null ? null : TrainerClassModel.fromJson(data);
  }

  Future<void> updateClass({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    await _apiClient.patch(ApiEndpoints.trainerClassById(id), body: payload);
  }

  Future<Map<String, dynamic>?> requestReschedule({
    required String id,
    required List<AvailabilitySlotModel> availableSlots,
    required String note,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.trainerClassReschedule(id),
      body: {
        'availableSlots': availableSlots.map((slot) => slot.toJson()).toList(),
        'note': note,
      },
    );
    return _extractObjectOrNull(response);
  }

  Future<void> completeBooking(String bookingId) async {
    await _apiClient.patch(ApiEndpoints.trainerBookingComplete(bookingId));
  }

  Future<void> acceptReschedule(String bookingId) async {
    await _apiClient.patch(
      ApiEndpoints.trainerBookingRescheduleAccept(bookingId),
    );
  }

  Future<void> deleteClass(String id) async {
    await _apiClient.delete(ApiEndpoints.trainerClassById(id));
  }

  /// GET /api/trainer/dashboard/earnings
  /// [period] = 'monthly' | 'weekly' | 'yearly'
  /// [year]   required for monthly (defaults to current year on server)
  /// [date]   ISO date string required for weekly (e.g. '2026-05-24')
  Future<TrainerEarningsModel> getEarnings({
    required String period,
    int? year,
    String? date,
  }) async {
    final params = <String, dynamic>{'period': period};
    if (year != null) params['year'] = year;
    if (date != null) params['date'] = date;

    final response = await _apiClient.get(
      ApiEndpoints.trainerDashboardEarnings,
      queryParameters: params,
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }
    return TrainerEarningsModel.fromJson(response);
  }

  /// GET /api/trainer/dashboard/top-classes
  Future<List<TrainerTopClassModel>> getTopClasses() async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerDashboardTopClasses,
    );
    final list = response is Map<String, dynamic>
        ? (response['data'] as List? ?? [])
        : (response is List ? response : []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(TrainerTopClassModel.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['items', 'classes', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    for (final key in const ['items', 'classes', 'results']) {
      final value = response[key];
      if (value is List) return value;
    }

    return const [];
  }

  Map<String, dynamic>? _extractObjectOrNull(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    if (response.isEmpty) return null;

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['class'] ?? data['service'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }

    final nested = response['class'] ?? response['service'];
    if (nested is Map<String, dynamic>) return nested;

    if (response.containsKey('message') && response.length == 1) {
      return null;
    }

    return response;
  }
}
