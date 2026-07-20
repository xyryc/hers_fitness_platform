import 'dart:io';

import 'package:fitness/Helpers/route.dart';
import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/services/auth_service.dart';
import 'package:fitness/services/fcm_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/auth_role.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class SignInController extends GetxController {
  SignInController({
    AuthService? authService,
    UserService? userService,
    TokenStorage? tokenStorage,
  }) : _authService = authService ?? AuthService(),
       _userService = userService ?? UserService(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthService _authService;
  final UserService _userService;
  final TokenStorage _tokenStorage;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final rememberMe = false.obs;

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAppSnackbar(
        'Missing information',
        'Please enter your email and password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final deviceId = await _tokenStorage.getClientId();
      final authResponse = await _authService.signIn(
        username: email,
        password: password,
        rememberMe: rememberMe.value,
        fcmToken: fcmToken,
        devicePlatform: Platform.isIOS ? 'IOS' : 'ANDROID',
        deviceId: deviceId,
      );

      final role = await _resolveRole(authResponse.user?.role);
      if (role == 'trainer') {
        await FcmService.instance.registerCurrentToken();
        Get.offAllNamed(AppRoutes.trainerBottomNavScreen);
        return;
      }

      if (role == 'member') {
        await FcmService.instance.registerCurrentToken();
        Get.offAllNamed(AppRoutes.memberBottomNavScreen);
        return;
      }

      showAppSnackbar(
        'Sign in failed',
        'Could not determine your account role. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      showAppSnackbar(
        'Sign in failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Sign in failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  Future<String?> _resolveRole(String? loginRole) async {
    final parsedLoginRole = normalizeUserRole(loginRole);
    if (parsedLoginRole != null) {
      await _tokenStorage.saveUserRole(parsedLoginRole);
      return parsedLoginRole;
    }

    try {
      final currentUser = await _userService.getCurrentUser();
      final profileRole = normalizeUserRole(currentUser.role);
      if (profileRole != null) {
        await _tokenStorage.saveUserRole(profileRole);
      }
      return profileRole;
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
