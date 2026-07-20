import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/member_class_model.dart';

class MemberClassService {
  MemberClassService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<MemberClassModel>> getClasses({String? trainerUserId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.memberClasses,
      queryParameters: {
        if (trainerUserId != null && trainerUserId.trim().isNotEmpty)
          'trainerUserId': trainerUserId.trim(),
      },
    );
    return _extractList(
      response,
    ).whereType<Map<String, dynamic>>().map(MemberClassModel.fromJson).toList();
  }

  Future<BookingHoldModel> holdBooking({
    required String classId,
    required bool isMonthlySession,
    required List<String> availabilitySlotIds,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String location,
    required String selectedClassType,
    required String comment,
    required String couponCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.memberClassBookings(classId),
      body: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'location': location,
        'selectedClassType': selectedClassType,
        'comment': comment,
        if (isMonthlySession)
          'availabilitySlotIds': availabilitySlotIds
        else
          'availabilitySlotId': availabilitySlotIds.first,
        if (couponCode.trim().isNotEmpty) 'couponCode': couponCode.trim(),
      },
    );
    return BookingHoldModel.fromJson(_extractObject(response));
  }

  Future<StripePaymentIntentModel> createStripePaymentIntent(
    String paymentId,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.memberStripePaymentIntent(paymentId),
    );
    return StripePaymentIntentModel.fromJson(_extractObject(response));
  }

  Future<void> confirmStripePayment({
    required String paymentId,
    required String paymentIntentId,
  }) async {
    await _apiClient.post(
      ApiEndpoints.memberBookingPaymentConfirm(paymentId),
      body: {
        'provider': 'stripe',
        'paymentMethod': 'card',
        'providerSessionId': paymentIntentId,
      },
    );
  }

  Future<void> failStripePayment({
    required String paymentId,
    String? paymentIntentId,
  }) async {
    await _apiClient.post(
      ApiEndpoints.memberBookingPaymentFail(paymentId),
      body: {
        'provider': 'stripe',
        'paymentMethod': 'card',
        if (paymentIntentId != null && paymentIntentId.isNotEmpty)
          'providerSessionId': paymentIntentId,
      },
    );
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

  Map<String, dynamic> _extractObject(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }
}
