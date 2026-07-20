import 'package:fitness/Helpers/route.dart';
import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class PasswordRecoveryController extends GetxController {
  PasswordRecoveryController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final code = ''.obs;
  final resetKey = ''.obs;
  final isSendingCode = false.obs;
  final isVerifyingCode = false.obs;
  final isResettingPassword = false.obs;

  Future<void> sendForgotPasswordCode() async {
    final email = _emailFromArgsOrController;
    if (email.isEmpty) {
      showAppSnackbar(
        'Email required',
        'Please enter your email address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSendingCode.value = true;
      await _authService.forgotPassword(email: email);
      Get.toNamed(
        AppRoutes.passwordVerificationScreen,
        arguments: {'flow': 'forgotPassword', 'email': email},
      );
    } on ApiException catch (error) {
      showAppSnackbar(
        'Reset failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Reset failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSendingCode.value = false;
    }
  }

  Future<void> verifyEmailCode() async {
    final email = _emailFromArgsOrController;
    final currentCode = code.value.trim();

    if (email.isEmpty || currentCode.length != 6) {
      showAppSnackbar(
        'Invalid code',
        'Please enter the 6-digit code sent to your email.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isVerifyingCode.value = true;
      final key = await _authService.verifyPasswordResetOtp(
        email: email,
        otp: currentCode,
      );
      resetKey.value = key;
      Get.toNamed(
        AppRoutes.changePasswordScreen,
        arguments: {'email': email, 'resetKey': key},
      );
    } on ApiException catch (error) {
      showAppSnackbar(
        'Verification failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Verification failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isVerifyingCode.value = false;
    }
  }

  Future<void> resetPassword() async {
    final email = _emailFromArgsOrController;
    final currentResetKey = _resetKeyFromArgsOrController;
    final newPassword = newPasswordController.text;
    final confirmNewPassword = confirmPasswordController.text;

    if (email.isEmpty || currentResetKey.isEmpty) {
      showAppSnackbar(
        'Reset failed',
        'Email or reset key is missing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword.isEmpty || confirmNewPassword.isEmpty) {
      showAppSnackbar(
        'Password required',
        'Please enter and confirm your new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmNewPassword) {
      showAppSnackbar(
        'Password mismatch',
        'New password and confirm password do not match.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isResettingPassword.value = true;
      await _authService.resetPassword(
        resetKey: currentResetKey,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      showAppSnackbar(
        'Password updated',
        'Please sign in with your new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.signInScreen);
    } on ApiException catch (error) {
      showAppSnackbar(
        'Reset failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Reset failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isResettingPassword.value = false;
    }
  }

  String get _emailFromArgsOrController {
    final args = Get.arguments;
    if (args is Map && args['email'] is String) {
      return args['email'] as String;
    }
    return emailController.text.trim();
  }

  String get _resetKeyFromArgsOrController {
    final args = Get.arguments;
    if (args is Map && args['resetKey'] is String) {
      return args['resetKey'] as String;
    }
    return resetKey.value.trim();
  }

  @override
  void onClose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
