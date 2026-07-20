import 'dart:async';
import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/services/fcm_service.dart';
import 'package:fitness/models/auth_response_model.dart';
import 'package:fitness/models/member_register_payload.dart';
import 'package:fitness/models/trainer_register_payload.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient.instance,
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthResponseModel> signIn({
    required String username,
    required String password,
    bool rememberMe = false,
    String? fcmToken,
    String? devicePlatform,
    String? deviceId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.signIn,
      body: {
        'username': username,
        'password': password,
        'rememberMe': rememberMe,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        if (devicePlatform != null && devicePlatform.isNotEmpty)
          'devicePlatform': devicePlatform,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
    );

    final authResponse = _parseAuthResponse(response);
    await _saveAuthResponse(authResponse);

    return authResponse;
  }

  Future<AuthResponseModel> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException('Refresh token not found');
    }

    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      body: {'refreshToken': refreshToken},
    );

    final authResponse = _parseAuthResponse(response);
    await _saveAuthResponse(authResponse);

    // Re-register FCM token after session refresh
    unawaited(FcmService.instance.registerCurrentToken());

    return authResponse;
  }

  Future<dynamic> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyEmail,
      body: {'email': email, 'code': code},
    );
    await _savePossibleAuthResponse(response);
    return response;
  }

  Future<dynamic> resendVerification({required String email}) async {
    return _apiClient.post(
      ApiEndpoints.resendVerification,
      body: {'email': email},
    );
  }

  Future<dynamic> forgotPassword({required String email}) async {
    return _apiClient.post(ApiEndpoints.forgotPassword, body: {'email': email});
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyPasswordResetOtp,
      body: {'email': email, 'otp': otp},
    );

    final resetKey = _extractString(response, const [
      'resetKey',
      'reset_key',
      'token',
    ]);
    if (resetKey == null || resetKey.isEmpty) {
      throw const ApiException('Reset key not found in server response');
    }

    return resetKey;
  }

  Future<dynamic> resetPassword({
    required String resetKey,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    return _apiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'resetKey': resetKey,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> _saveAuthResponse(AuthResponseModel authResponse) async {
    if (authResponse.accessToken.isNotEmpty) {
      await _tokenStorage.saveAuthTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
    }

    final role = authResponse.user?.role;
    if (role != null && role.isNotEmpty) {
      await _tokenStorage.saveUserRole(role);
    }
  }

  AuthResponseModel _parseAuthResponse(dynamic response) {
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> _savePossibleAuthResponse(dynamic response) async {
    if (response is! Map<String, dynamic>) return;

    final authResponse = AuthResponseModel.fromJson(response);
    if (authResponse.accessToken.isEmpty && authResponse.user?.role == null) {
      return;
    }

    await _saveAuthResponse(authResponse);
  }

  String? _extractString(dynamic response, List<String> keys) {
    if (response is! Map<String, dynamic>) return null;

    for (final key in keys) {
      final value = response[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return null;
  }

  Future<dynamic> registerMember(MemberRegisterPayload payload) async {
    try {
      _ensureFileExists(payload.imagePath, 'Profile image');
      _ensureFileExists(payload.idCardFrontImagePath, 'ID card front image');
      _ensureFileExists(payload.idCardBackImagePath, 'ID card back image');

      final response = await _apiClient.multipartPost(
        endpoint: ApiEndpoints.memberSignUp,
        fields: payload.fields,
        files: await payload.toMultipartFiles(),
      );
      await _savePossibleAuthResponse(response);
      return response;
    } on ApiException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ApiException(error.message);
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  Future<dynamic> registerTrainer(TrainerRegisterPayload payload) async {
    try {
      _ensureFileExists(payload.imagePath, 'Profile image');
      _ensureFileExists(payload.idCardFrontImagePath, 'ID card front image');
      _ensureFileExists(payload.idCardBackImagePath, 'ID card back image');

      final response = await _apiClient.multipartPost(
        endpoint: ApiEndpoints.trainerSignUp,
        fields: payload.fields,
        files: await payload.toMultipartFiles(),
      );
      await _savePossibleAuthResponse(response);
      return response;
    } on ApiException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ApiException(error.message);
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  void _ensureFileExists(String path, String label) {
    if (path.trim().isEmpty) {
      throw ApiException('$label is missing. Please select it again.');
    }

    if (!File(path).existsSync()) {
      throw ApiException('$label file was not found. Please select it again.');
    }
  }

  Future<void> logout() async {
    try {
      await FcmService.instance.deleteToken();
      await _apiClient.post(ApiEndpoints.logout);
    } finally {
      await _tokenStorage.clear();
    }
  }
}
