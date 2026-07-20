import 'dart:io';

import 'package:fitness/Helpers/route.dart';
import 'package:fitness/utils/AppConstants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class MemberRegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  final locationController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isFormValid = false.obs;
  final imagePath = RxnString();

  static const _passwordPolicyMessage =
      'Password must be at least 8 characters and include uppercase, lowercase, number, and special character.';

  @override
  void onInit() {
    super.onInit();
    for (final controller in _watchedControllers) {
      controller.addListener(_updateFormValidity);
    }
    imagePath.listen((_) => _updateFormValidity());
    _updateFormValidity();
  }

  List<TextEditingController> get _watchedControllers => [
    nameController,
    emailController,
    phoneController,
    stateController,
    locationController,
    passwordController,
    confirmPasswordController,
  ];

  void setProfileImage(File file) {
    imagePath.value = file.path;
  }

  void continueToIdentityVerification() {
    final validationMessage = _validate();
    if (validationMessage != null) {
      showAppSnackbar(
        'Registration incomplete',
        validationMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(
      AppRoutes.verifyIdentityScreen,
      arguments: {'role': 'member', 'memberRegisterDraft': _draft},
    );
  }

  void continueToPasswordVerification() {
    continueToIdentityVerification();
  }

  Map<String, String>? get identityVerificationDraft {
    if (_validate() != null) return null;
    return _draft;
  }

  Map<String, String> get _draft {
    return {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'state': stateController.text.trim(),
      'location': locationController.text.trim(),
      'timezone': DateTime.now().timeZoneName,
      'password': passwordController.text,
      'confirmPassword': confirmPasswordController.text,
      'imagePath': imagePath.value!,
    };
  }

  String? _validate() {
    final requiredValues = {
      'name': nameController.text,
      'email': emailController.text,
      'phone number': phoneController.text,
      'state': stateController.text,
      'location': locationController.text,
      'password': passwordController.text,
      'confirm password': confirmPasswordController.text,
    };

    for (final entry in requiredValues.entries) {
      if (entry.value.trim().isEmpty) {
        return 'Please enter ${entry.key}.';
      }
    }

    if (!AppConstants.emailValidator.hasMatch(emailController.text.trim())) {
      return 'Please enter a valid email address.';
    }

    if (!AppConstants.passwordValidator.hasMatch(passwordController.text)) {
      return _passwordPolicyMessage;
    }

    if (passwordController.text != confirmPasswordController.text) {
      return 'Password and confirm password do not match.';
    }

    if (imagePath.value == null) {
      return 'Please select a profile image.';
    }

    return null;
  }

  void _updateFormValidity() {
    final isValid =
        nameController.text.trim().isNotEmpty &&
        AppConstants.emailValidator.hasMatch(emailController.text.trim()) &&
        phoneController.text.trim().isNotEmpty &&
        stateController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        AppConstants.passwordValidator.hasMatch(passwordController.text) &&
        passwordController.text == confirmPasswordController.text &&
        imagePath.value != null;

    isFormValid.value = isValid;
  }

  @override
  void onClose() {
    for (final controller in _watchedControllers) {
      controller.removeListener(_updateFormValidity);
    }
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    stateController.dispose();
    locationController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
