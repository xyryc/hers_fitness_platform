import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/member_activity_model.dart';
import 'package:fitness/models/referral_model.dart';
import 'package:fitness/models/static_content_model.dart';
import 'package:fitness/models/trainer_transaction_model.dart';
import 'package:fitness/models/transaction_model.dart';
import 'package:fitness/models/payout_status_model.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:http/http.dart' as http;

class UpdateProfileRequest {
  final String? displayName;
  final String? phoneNumber;
  final String? state;
  final String? location;
  final int? age;
  final double? weight;
  final String? weightUnit;
  final String? dietPreference;

  const UpdateProfileRequest({
    this.displayName,
    this.phoneNumber,
    this.state,
    this.location,
    this.age,
    this.weight,
    this.weightUnit,
    this.dietPreference,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (displayName != null) map['displayName'] = displayName;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (state != null) map['state'] = state;
    if (location != null) map['location'] = location;
    if (age != null) map['age'] = age;
    if (weight != null) map['weight'] = weight;
    if (weightUnit != null) map['weightUnit'] = weightUnit;
    if (dietPreference != null) map['dietPreference'] = dietPreference;
    return map;
  }
}

// ── Trainer profile update request ────────────────────────────────────────────

class UpdateTrainerProfileRequest {
  final String? displayName;
  final String? phoneNumber;
  final String? state;
  final String? location;
  final String? bio;
  final List<String>? fitnessClasses;
  final String? instructorDuration;
  final String? certifications;
  final String? sessionFormat;

  const UpdateTrainerProfileRequest({
    this.displayName,
    this.phoneNumber,
    this.state,
    this.location,
    this.bio,
    this.fitnessClasses,
    this.instructorDuration,
    this.certifications,
    this.sessionFormat,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (displayName != null) map['displayName'] = displayName;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (state != null) map['state'] = state;
    if (location != null) map['location'] = location;
    if (bio != null) map['bio'] = bio;
    if (fitnessClasses != null) map['fitnessClasses'] = fitnessClasses;
    if (instructorDuration != null)
      map['instructorDuration'] = instructorDuration;
    if (certifications != null) map['certifications'] = certifications;
    if (sessionFormat != null) map['sessionFormat'] = sessionFormat;
    return map;
  }
}

class UserService {
  UserService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<UserProfileModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    return UserProfileModel.fromJson(_asMap(response));
  }

  Future<UserProfileModel> updateProfile(UpdateProfileRequest body) async {
    final response = await _apiClient.patch(
      ApiEndpoints.memberUpdateProfile,
      body: body.toJson(),
    );
    return UserProfileModel.fromJson(_asMap(response));
  }

  Future<UserProfileModel> uploadImages({
    File? profileImage,
    File? coverImage,
  }) async {
    final files = <http.MultipartFile>[];

    if (profileImage != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          filename: 'profile.jpg',
        ),
      );
    }

    if (coverImage != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'coverImage',
          coverImage.path,
          filename: 'cover.jpg',
        ),
      );
    }

    final response = await _apiClient.multipartPost(
      endpoint: ApiEndpoints.memberProfileImages,
      fields: const {},
      files: files,
    );
    return UserProfileModel.fromJson(_asMap(response));
  }

  Future<MemberDailyActivityModel> getMemberDailyActivity({
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.memberDailyActivity,
      queryParameters: {'month': month, 'year': year},
    );
    return MemberDailyActivityModel.fromJson(_asMap(response));
  }

  Future<MemberMonthlyActivityModel> getMemberMonthlyActivity({
    required int year,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.memberMonthlyActivity,
      queryParameters: {'year': year},
    );
    return MemberMonthlyActivityModel.fromJson(_asMap(response));
  }

  Future<MemberWeeklyActivityModel> getMemberWeeklyActivity({
    DateTime? date,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.memberWeeklyActivity,
      queryParameters: date == null
          ? null
          : {
              'date':
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            },
    );
    return MemberWeeklyActivityModel.fromJson(_asMap(response));
  }

  Future<MemberYearlyActivityModel> getMemberYearlyActivity() async {
    final response = await _apiClient.get(ApiEndpoints.memberYearlyActivity);
    return MemberYearlyActivityModel.fromJson(_asMap(response));
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _apiClient.get(ApiEndpoints.memberTransactions);
    final map = _asMap(response);
    final list = (map['data'] ?? map) as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }

  Future<ReferralModel> getReferral() async {
    final response = await _apiClient.get(ApiEndpoints.memberReferral);
    return ReferralModel.fromJson(_asMap(response));
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete(ApiEndpoints.memberAccount);
  }

  // ── Trainer-specific methods ───────────────────────────────────────────────

  /// PATCH /api/users/trainer/profile
  Future<UserProfileModel> updateTrainerProfile(
    UpdateTrainerProfileRequest body,
  ) async {
    final response = await _apiClient.patch(
      ApiEndpoints.trainerUpdateProfile,
      body: body.toJson(),
    );
    return UserProfileModel.fromJson(_asMap(response));
  }

  /// POST /api/users/trainer/profile/images  (multipart)
  Future<UserProfileModel> uploadTrainerImages({
    File? profileImage,
    File? coverImage,
  }) async {
    final files = <http.MultipartFile>[];

    if (profileImage != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          filename: 'profile.jpg',
        ),
      );
    }

    if (coverImage != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'coverImage',
          coverImage.path,
          filename: 'cover.jpg',
        ),
      );
    }

    final response = await _apiClient.multipartPost(
      endpoint: ApiEndpoints.trainerProfileImages,
      fields: const {},
      files: files,
    );
    return UserProfileModel.fromJson(_asMap(response));
  }

  /// GET /api/users/trainer/transactions
  Future<List<TrainerTransactionModel>> getTrainerTransactions({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;

    final response = await _apiClient.get(
      ApiEndpoints.trainerTransactions,
      queryParameters: params,
    );
    final map = _asMap(response);
    final list = (map['data'] ?? map) as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TrainerTransactionModel.fromJson)
        .toList();
  }

  /// DELETE /api/users/trainer/account
  Future<void> deleteTrainerAccount() async {
    await _apiClient.delete(ApiEndpoints.trainerAccount);
  }

  /// GET /api/users/trainer/payout/status
  Future<PayoutStatusModel> getTrainerPayoutStatus() async {
    final response = await _apiClient.get(ApiEndpoints.trainerPayoutStatus);
    return PayoutStatusModel.fromJson(_asMap(response));
  }

  /// POST /api/users/trainer/payout/onboarding-link
  Future<PayoutStatusModel> generateTrainerOnboardingLink({
    String returnUrl =
        'https://hersfitness.okaybro.online/trainer/payout/return',
    String refreshUrl =
        'https://hersfitness.okaybro.online/trainer/payout/refresh',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.trainerPayoutOnboardingLink,
      body: {'returnUrl': returnUrl, 'refreshUrl': refreshUrl},
    );
    return PayoutStatusModel.fromJson(_asMap(response));
  }

  Future<StaticContentModel> getStaticContent(String key) async {
    final response = await _apiClient.get(ApiEndpoints.staticContent(key));
    return StaticContentModel.fromJson(_asMap(response));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _apiClient.put(
      ApiEndpoints.users,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const ApiException('Invalid server response');
  }
}
