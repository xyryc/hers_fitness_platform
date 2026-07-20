import 'dart:io';

import 'package:fitness/Helpers/route.dart';
import 'package:fitness/utils/AppConstants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class TrainerRegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final classesTaughtController = TextEditingController();
  final instructorExperienceController = TextEditingController();
  final certificationsController = TextEditingController();
  final classDeliveryModeController = TextEditingController(text: 'BOTH');
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isFormValid = false.obs;
  final imagePath = RxnString();

  final classesTaughtTags = <String>[].obs;
  final certificationsTags = <String>[].obs;

  static const _passwordPolicyMessage =
      'Password must be at least 8 characters and include uppercase, lowercase, number, and special character.';

  @override
  void onInit() {
    super.onInit();
    for (final controller in _watchedControllers) {
      controller.addListener(_updateFormValidity);
    }
    imagePath.listen((_) => _updateFormValidity());
    classesTaughtTags.listen((_) => _updateFormValidity());
    certificationsTags.listen((_) => _updateFormValidity());
    _updateFormValidity();
  }

  List<TextEditingController> get _watchedControllers => [
    nameController,
    emailController,
    phoneController,
    stateController,
    locationController,
    bioController,
    instructorExperienceController,
    classDeliveryModeController,
    passwordController,
    confirmPasswordController,
  ];

  void setProfileImage(File file) {
    imagePath.value = file.path;
  }

  void addClassTag(String tag) {
    if (tag.trim().isNotEmpty && !classesTaughtTags.contains(tag.trim())) {
      classesTaughtTags.add(tag.trim());
      classesTaughtController.clear();
      _updateFormValidity();
    }
  }

  void removeClassTag(String tag) {
    classesTaughtTags.remove(tag);
    _updateFormValidity();
  }

  void addCertificationTag(String tag) {
    if (tag.trim().isNotEmpty && !certificationsTags.contains(tag.trim())) {
      certificationsTags.add(tag.trim());
      certificationsController.clear();
      _updateFormValidity();
    }
  }

  void removeCertificationTag(String tag) {
    certificationsTags.remove(tag);
    _updateFormValidity();
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
      arguments: {'role': 'trainer', 'trainerRegisterDraft': _draft},
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
      'bio': bioController.text.trim(),
      'classesTaught': classesTaughtTags.join('|'),
      'instructorExperience': instructorExperienceController.text.trim(),
      'certifications': certificationsTags.join('|'),
      'classDeliveryMode': _normalizedDeliveryMode,
      'password': passwordController.text,
      'confirmPassword': confirmPasswordController.text,
      'imagePath': imagePath.value!,
    };
  }

  String get _normalizedDeliveryMode {
    final value = classDeliveryModeController.text.trim().toLowerCase();

    if (value == 'online') return 'ONLINE';
    if (value == 'in person' || value == 'in_person' || value == 'offline') {
      return 'OFFLINE';
    }
    return 'BOTH';
  }

  String? _validate() {
    final requiredValues = {
      'name': nameController.text,
      'email': emailController.text,
      'phone number': phoneController.text,
      'state': stateController.text,
      'location': locationController.text,
      'bio': bioController.text,
      'experience': instructorExperienceController.text,
      'class delivery mode': classDeliveryModeController.text,
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

    if (classesTaughtTags.isEmpty) {
      return 'Please enter at least one fitness class you teach.';
    }

    if (certificationsTags.isEmpty) {
      return 'Please enter at least one certification/qualification.';
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
        bioController.text.trim().isNotEmpty &&
        classesTaughtTags.isNotEmpty &&
        instructorExperienceController.text.trim().isNotEmpty &&
        certificationsTags.isNotEmpty &&
        classDeliveryModeController.text.trim().isNotEmpty &&
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
    bioController.dispose();
    classesTaughtController.dispose();
    instructorExperienceController.dispose();
    certificationsController.dispose();
    classDeliveryModeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
