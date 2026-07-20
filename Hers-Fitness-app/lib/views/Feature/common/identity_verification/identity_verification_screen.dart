import 'dart:io';

import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/auth/member_register_controller.dart';
import 'package:fitness/controllers/auth/trainer_register_controller.dart';
import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/member_register_payload.dart';
import 'package:fitness/models/trainer_register_payload.dart';
import 'package:fitness/services/auth_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppIcons/app_icons.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';

enum IdentityCardSide { front, back }

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  String? selectedDocument;
  String? frontImagePath;
  String? backImagePath;
  final TextEditingController idCardNumberController = TextEditingController();
  late final String role;
  late final Map<String, String>? trainerRegisterDraft;
  late final Map<String, String>? memberRegisterDraft;

  @override
  void initState() {
    super.initState();
    role = _identityRoleFromArgs();
    trainerRegisterDraft =
        _trainerRegisterDraftFromArgs() ??
        _trainerRegisterDraftFromController();
    memberRegisterDraft =
        _memberRegisterDraftFromArgs() ?? _memberRegisterDraftFromController();
  }

  @override
  void dispose() {
    idCardNumberController.dispose();
    super.dispose();
  }

  void _showDocumentSelection() {
    Get.bottomSheet(
      const IdentityDocumentTypeScreen(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((result) {
      if (result is String && mounted) {
        setState(() => selectedDocument = result);
      }
    });
  }

  Future<void> _pickImage(IdentityCardSide side) async {
    await Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              "Select Source",
              style: AppTextStyles.base16SemiBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.actionPrimary,
              ),
              title: const AppText("Take a Photo"),
              onTap: () {
                Get.back();
                _captureFromCamera(side);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.actionPrimary,
              ),
              title: const AppText("Choose from Gallery"),
              onTap: () {
                Get.back();
                _pickFromGallery(side);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(IdentityCardSide side) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() {
        if (side == IdentityCardSide.front) {
          frontImagePath = image.path;
        } else {
          backImagePath = image.path;
        }
      });
    }
  }

  void _captureFromCamera(IdentityCardSide side) {
    Get.toNamed(
      AppRoutes.identityCameraScreen,
      arguments: _identityArgs(
        role,
        side,
        documentType: selectedDocument,
        idCardNumber: idCardNumberController.text.trim(),
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        trainerRegisterDraft: trainerRegisterDraft,
        memberRegisterDraft: memberRegisterDraft,
      ),
    )?.then((result) {
      if (result is String && mounted) {
        setState(() {
          if (side == IdentityCardSide.front) {
            frontImagePath = result;
          } else {
            backImagePath = result;
          }
        });
      }
    });
  }

  void _submit() {
    final idCardNumber = idCardNumberController.text.trim();
    if (selectedDocument == null ||
        idCardNumber.isEmpty ||
        frontImagePath == null ||
        backImagePath == null) {
      showAppSnackbar(
        "Incomplete Information",
        "Please select a document, enter the ID number, and provide both front and back photos.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(
      AppRoutes.identityReviewScreen,
      arguments: _identityArgs(
        role,
        IdentityCardSide
            .back, // review screen expects back for some reason in existing code
        documentType: selectedDocument,
        idCardNumber: idCardNumber,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        trainerRegisterDraft: trainerRegisterDraft,
        memberRegisterDraft: memberRegisterDraft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        selectedDocument != null &&
        idCardNumberController.text.trim().isNotEmpty &&
        frontImagePath != null &&
        backImagePath != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 24.h;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          const _VerificationHeader(title: 'Verify identity'),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, bottomPadding),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  _GovernmentIdCard(
                    selectedLabel: selectedDocument,
                    onSelect: _showDocumentSelection,
                  ),
                  SizedBox(height: 24.h),

                  Row(
                    children: [
                      Expanded(
                        child: _IdImageSlot(
                          label: "Front Side",
                          imagePath: frontImagePath,
                          onTap: () => _pickImage(IdentityCardSide.front),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _IdImageSlot(
                          label: "Back Side",
                          imagePath: backImagePath,
                          onTap: () => _pickImage(IdentityCardSide.back),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  CustomTextField(
                    hintText: 'Enter ID card number',
                    controller: idCardNumberController,
                    filColor: AppColors.bgPrimary,
                    borderColor: AppColors.actionPrimary,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  _PrimaryOrDisabledButton(
                    text: 'Verify my identity',
                    enabled: hasSelection,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdImageSlot extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTap;

  const _IdImageSlot({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderPrimary),
              image: imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null
                ? const Center(
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.actionPrimary,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class IdentityDocumentTypeScreen extends StatelessWidget {
  const IdentityDocumentTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 396.h,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 26.h),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(46.r),
          topRight: Radius.circular(46.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 150.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.actionSecondary,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 34.h),
          AppText(
            "Let's get you verified!",
            style: AppTextStyles.base16SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            'Which Photo ID would you Like to use?',
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 24.h),
          _DocumentOptionTile(
            title: "Driver's License",
            onTap: () => Get.back(result: "Driver's License"),
          ),
          _DividerLine(margin: EdgeInsets.symmetric(horizontal: 8.w)),
          _DocumentOptionTile(
            title: 'National ID Card',
            selected: true,
            onTap: () => Get.back(result: 'National ID Card'),
          ),
          _DividerLine(margin: EdgeInsets.symmetric(horizontal: 8.w)),
          _DocumentOptionTile(
            title: 'Passport',
            onTap: () => Get.back(result: 'Passport'),
          ),
          const Spacer(),
          _DividerLine(margin: EdgeInsets.symmetric(horizontal: 8.w)),
        ],
      ),
    );
  }
}

class IdentityCameraScreen extends StatefulWidget {
  const IdentityCameraScreen({super.key});

  @override
  State<IdentityCameraScreen> createState() => _IdentityCameraScreenState();
}

class _IdentityCameraScreenState extends State<IdentityCameraScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  bool isCapturing = false;
  bool isFlashOn = false;
  double zoomLevel = 1;

  @override
  void initState() {
    super.initState();
    _cameraInitFuture = _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  IdentityCardSide get side => _identitySideFromArgs();

  String get role => _identityRoleFromArgs();

  String get documentType => _identityDocumentTypeFromArgs();

  String get idCardNumber => _identityIdCardNumberFromArgs();

  Map<String, String>? get trainerRegisterDraft =>
      _trainerRegisterDraftFromArgs() ?? _trainerRegisterDraftFromController();

  Map<String, String>? get memberRegisterDraft =>
      _memberRegisterDraftFromArgs() ?? _memberRegisterDraftFromController();

  String? get frontImagePath => _identityStringArg('frontImagePath');

  String? get backImagePath => _identityStringArg('backImagePath');

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found');
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();
      await _focusOnCard();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;

      showAppSnackbar(
        'Camera unavailable',
        'Please check camera permission and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _focusOnCard() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}

    try {
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}

    await _setFocusPoint(const Offset(0.5, 0.5));
  }

  Future<void> _setFocusPoint(Offset point) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setFocusPoint(point);
    } catch (_) {}

    try {
      await controller.setExposurePoint(point);
    } catch (_) {}
  }

  Future<void> _toggleZoom() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final nextZoom = zoomLevel == 1 ? 2.0 : 1.0;

    try {
      final maxZoom = await controller.getMaxZoomLevel();
      final safeZoom = nextZoom > maxZoom ? maxZoom : nextZoom;
      await controller.setZoomLevel(safeZoom);

      if (mounted) {
        setState(() => zoomLevel = safeZoom == 1 ? 1 : 2);
      }
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final nextValue = !isFlashOn;
      await controller.setFlashMode(
        nextValue ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() => isFlashOn = nextValue);
      }
    } catch (_) {}
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => isCapturing = true);

    try {
      await _focusOnCard();
      final capturedImage = await controller.takePicture();
      if (!mounted) return;

      Get.toNamed(
        AppRoutes.identityCheckQualityScreen,
        arguments: _identityArgs(
          role,
          side,
          documentType: documentType,
          idCardNumber: idCardNumber,
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
          capturedImagePath: capturedImage.path,
          trainerRegisterDraft: trainerRegisterDraft,
          memberRegisterDraft: memberRegisterDraft,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      showAppSnackbar(
        'Camera unavailable',
        'Please check camera permission and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBack = side == IdentityCardSide.back;

    return Scaffold(
      backgroundColor: const Color(0xFFC2BEBD),
      body: Column(
        children: [
          _VerificationHeader(
            title: isBack ? 'Back of card' : 'Verify identity',
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: isBack ? 116.h : 110.h,
                  left: 22.w,
                  right: 22.w,
                  child: _CameraFocusCard(
                    controller: _cameraController,
                    initFuture: _cameraInitFuture,
                    onFocusPoint: _setFocusPoint,
                  ),
                ),
                Positioned(
                  left: 50.w,
                  right: 50.w,
                  bottom: 46.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CameraSmallControl(
                        label: zoomLevel == 1 ? '2x' : '1x',
                        onTap: _toggleZoom,
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 72.w,
                          height: 72.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4.w),
                          ),
                          child: Center(
                            child: isCapturing
                                ? SizedBox(
                                    width: 26.w,
                                    height: 26.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5.w,
                                      color: AppColors.actionPrimary,
                                    ),
                                  )
                                : Container(
                                    width: 58.w,
                                    height: 58.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD8D8D8),
                                        width: 2.w,
                                      ),
                                      color: AppColors.bgPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      _CameraSmallControl(
                        icon: isFlashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: _toggleFlash,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  child: Container(
                    width: 136.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: AppColors.actionSecondary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IdentityCheckQualityScreen extends StatelessWidget {
  const IdentityCheckQualityScreen({super.key});

  IdentityCardSide get side => _identitySideFromArgs();

  String get role => _identityRoleFromArgs();

  String get documentType => _identityDocumentTypeFromArgs();

  String get idCardNumber => _identityIdCardNumberFromArgs();

  Map<String, String>? get trainerRegisterDraft =>
      _trainerRegisterDraftFromArgs();

  Map<String, String>? get memberRegisterDraft =>
      _memberRegisterDraftFromArgs() ?? _memberRegisterDraftFromController();

  String? get capturedImagePath => _identityStringArg('capturedImagePath');

  String? get frontImagePath => _identityStringArg('frontImagePath');

  String? get backImagePath => _identityStringArg('backImagePath');

  void _continueFlow() {
    final currentImagePath = capturedImagePath;
    if (currentImagePath == null) {
      showAppSnackbar(
        'Photo missing',
        'Please take a photo again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Return the result to the previous screen (VerifyIdentityScreen)
    Get.back(result: currentImagePath);
  }

  void _retakePhoto() {
    Get.back(); // Go back to camera
  }

  @override
  Widget build(BuildContext context) {
    final isBack = side == IdentityCardSide.back;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _VerificationHeader(
            title: isBack ? 'Back of card' : 'Verify identity',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  _CapturedIdPreview(imagePath: capturedImagePath),
                  SizedBox(height: 24.h),
                  AppText(
                    'Check quality',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.base16SemiBold.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  AppText(
                    'Please make sure your card details are clear to\nread with no blur or glare',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  AppButton(
                    text: isBack ? 'Submit' : 'Next',
                    height: 52.h,
                    borderRadius: 6.r,
                    onTap: _continueFlow,
                  ),
                  SizedBox(height: 20.h),
                  _OutlinedActionButton(
                    text: 'Take a new photo',
                    onTap: _retakePhoto,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IdentityReviewScreen extends StatelessWidget {
  const IdentityReviewScreen({super.key});

  String get role => _identityRoleFromArgs();

  String get documentType => _identityDocumentTypeFromArgs();

  String get idCardNumber => _identityIdCardNumberFromArgs();

  Map<String, String>? get trainerRegisterDraft =>
      _trainerRegisterDraftFromArgs() ?? _trainerRegisterDraftFromController();

  Map<String, String>? get memberRegisterDraft =>
      _memberRegisterDraftFromArgs() ?? _memberRegisterDraftFromController();

  String? get frontImagePath => _identityStringArg('frontImagePath');

  String? get backImagePath => _identityStringArg('backImagePath');

  bool get canSubmit =>
      frontImagePath != null &&
      backImagePath != null &&
      idCardNumber.isNotEmpty;

  String get homeRoute {
    if (_isTrainerRegistration) {
      return AppRoutes.trainerBottomNavScreen;
    }
    return AppRoutes.memberBottomNavScreen;
  }

  bool get _isTrainerRegistration =>
      role == 'trainer' || trainerRegisterDraft != null;

  bool get _isMemberRegistration =>
      role == 'member' && memberRegisterDraft != null;

  Future<void> _submitVerification() async {
    final frontPath = frontImagePath;
    final backPath = backImagePath;
    final cardNumber = idCardNumber;

    if (frontPath == null || backPath == null || cardNumber.isEmpty) {
      showAppSnackbar(
        'Information missing',
        'Please add your ID number and capture both sides of your ID.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final trainerDraft = trainerRegisterDraft;
    final memberDraft = memberRegisterDraft;

    if (_isTrainerRegistration && trainerDraft == null) {
      showAppSnackbar(
        'Registration incomplete',
        'Trainer registration information is missing. Please sign up again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_isMemberRegistration && memberDraft == null) {
      showAppSnackbar(
        'Registration incomplete',
        'Member registration information is missing. Please sign up again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _showLoadingDialog();

      if (_isTrainerRegistration && trainerDraft != null) {
        await AuthService().registerTrainer(
          TrainerRegisterPayload(
            name: trainerDraft['name'] ?? '',
            email: trainerDraft['email'] ?? '',
            phoneNumber: trainerDraft['phoneNumber'] ?? '',
            state: trainerDraft['state'] ?? '',
            location: trainerDraft['location'] ?? '',
            timezone: trainerDraft['timezone'],
            idCardType: _backendIdCardType(documentType),
            idCardNumber: cardNumber,
            bio: trainerDraft['bio'] ?? '',
            classesTaught: trainerDraft['classesTaught'] ?? '',
            instructorExperience: trainerDraft['instructorExperience'] ?? '',
            certifications: trainerDraft['certifications'] ?? '',
            classDeliveryMode: trainerDraft['classDeliveryMode'] ?? 'BOTH',
            password: trainerDraft['password'] ?? '',
            confirmPassword: trainerDraft['confirmPassword'] ?? '',
            imagePath: trainerDraft['imagePath'] ?? '',
            idCardFrontImagePath: frontPath,
            idCardBackImagePath: backPath,
          ),
        );

        if (Get.isDialogOpen == true) {
          Get.back();
        }

        Get.offAllNamed(
          AppRoutes.passwordVerificationScreen,
          arguments: {
            'flow': 'signup',
            'role': 'trainer',
            'email': trainerDraft['email'] ?? '',
            'password': trainerDraft['password'] ?? '',
            'nextRoute': AppRoutes.trainerBottomNavScreen,
            'backLabel': 'Back to Login',
          },
        );
        return;
      }

      if (_isMemberRegistration && memberDraft != null) {
        await AuthService().registerMember(
          MemberRegisterPayload(
            name: memberDraft['name'] ?? '',
            email: memberDraft['email'] ?? '',
            phoneNumber: memberDraft['phoneNumber'] ?? '',
            state: memberDraft['state'] ?? '',
            location: memberDraft['location'] ?? '',
            timezone: memberDraft['timezone'],
            idCardType: _backendIdCardType(documentType),
            idCardNumber: cardNumber,
            password: memberDraft['password'] ?? '',
            confirmPassword: memberDraft['confirmPassword'] ?? '',
            imagePath: memberDraft['imagePath'] ?? '',
            idCardFrontImagePath: frontPath,
            idCardBackImagePath: backPath,
          ),
        );

        if (Get.isDialogOpen == true) {
          Get.back();
        }

        Get.offAllNamed(
          AppRoutes.passwordVerificationScreen,
          arguments: {
            'flow': 'signup',
            'role': 'member',
            'email': memberDraft['email'] ?? '',
            'password': memberDraft['password'] ?? '',
            'nextRoute': AppRoutes.assessmentNumberOneScreen,
            'backLabel': 'Back to Login',
          },
        );
        return;
      }

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      _showSuccessDialog();
    } on ApiException catch (error) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      showAppSnackbar(
        'Verification failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      debugPrint('Trainer verification unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      showAppSnackbar(
        'Verification failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showLoadingDialog() {
    Get.dialog(
      Center(child: CircularProgressIndicator(color: AppColors.actionPrimary)),
      barrierDismissible: false,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(AppIcons.select, width: 50.w, height: 50.w),
              SizedBox(height: 24.h),
              AppText(
                'Thank you for submitting your\napplication. Our team will review your\napplication in the next 24-48 hours. We\nappreciate your patience, you will receive\na notification soon.',
                textAlign: TextAlign.center,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.22,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 26.h),
              AppButton(
                text: 'Done',
                height: 52.h,
                borderRadius: 6.r,
                onTap: () => Get.offAllNamed(homeRoute),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24.h;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          const _VerificationHeader(title: 'Verify identity'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, bottomPadding),
              child: Column(
                children: [
                  SizedBox(height: 26.h),
                  _GovernmentIdCard(completed: true),
                  SizedBox(height: 20.h),
                  _PrimaryOrDisabledButton(
                    text: 'Verify my identity',
                    enabled: canSubmit,
                    onTap: _submitVerification,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationHeader extends StatelessWidget {
  final String title;

  const _VerificationHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: topPadding + 100.h,
      padding: EdgeInsets.fromLTRB(22.w, topPadding + 22.h, 22.w, 22.h),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgPrimary,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.sp,
                color: AppColors.iconPrimary,
              ),
            ),
          ),
          Expanded(
            child: AppText(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.base16SemiBold.copyWith(
                color: AppColors.textInverse,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }
}

class _CapturedIdPreview extends StatelessWidget {
  final String? imagePath;

  const _CapturedIdPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: double.infinity,
        height: 192.h,
        color: const Color(0xFFA7A7A7),
        child: imagePath == null
            ? const SizedBox.shrink()
            : Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
      ),
    );
  }
}

class _GovernmentIdCard extends StatelessWidget {
  final bool completed;
  final String? selectedLabel;
  final VoidCallback? onSelect;

  const _GovernmentIdCard({
    this.completed = false,
    this.selectedLabel,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 218.h,
      padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.actionPrimary, width: 1.5.w),
      ),
      child: Column(
        children: [
          AppText(
            'Government ID',
            textAlign: TextAlign.center,
            style: AppTextStyles.base16SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 24.h),
          AppText(
            "This app is exclusively for women.\nID verification is required to help keep our members and trainers safe",
            textAlign: TextAlign.center,
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          if (completed)
            SvgPicture.asset(AppIcons.select, width: 52.w, height: 52.w)
          else
            GestureDetector(
              onTap: onSelect,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgSecondary,
                      border: Border.all(
                        color: AppColors.actionPrimary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      selectedLabel == null ? Icons.add : Icons.check,
                      color: AppColors.statusInfo,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  AppText(
                    selectedLabel ?? 'Select',
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.actionPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryOrDisabledButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryOrDisabledButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return AppButton(
        text: text,
        height: 52.h,
        borderRadius: 6.r,
        onTap: onTap,
      );
    }

    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Center(
        child: AppText(
          text,
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textDisabled,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _DocumentOptionTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DocumentOptionTile({
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: selected ? 82.h : 64.h,
        padding: EdgeInsets.symmetric(horizontal: selected ? 18.w : 10.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.borderFocusEffect,
                    blurRadius: 0,
                    spreadRadius: 4.w,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: selected ? 50.w : 40.w,
              height: selected ? 50.w : 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.bgPrimary : AppColors.bgSecondary,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.passport,
                  width: 22.w,
                  height: 22.w,
                  colorFilter: ColorFilter.mode(
                    AppColors.iconPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            AppText(
              title,
              style: AppTextStyles.sm14SemiBold.copyWith(
                color: selected ? AppColors.textInverse : AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const _DividerLine({required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.h,
      margin: margin,
      color: AppColors.borderPrimary,
    );
  }
}

class _CameraFocusCard extends StatelessWidget {
  final CameraController? controller;
  final Future<void>? initFuture;
  final ValueChanged<Offset> onFocusPoint;

  const _CameraFocusCard({
    required this.controller,
    required this.initFuture,
    required this.onFocusPoint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 218.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final point = Offset(
                (details.localPosition.dx / constraints.maxWidth)
                    .clamp(0, 1)
                    .toDouble(),
                (details.localPosition.dy / constraints.maxHeight)
                    .clamp(0, 1)
                    .toDouble(),
              );
              onFocusPoint(point);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                color: AppColors.bgPrimary,
                child: FutureBuilder<void>(
                  future: initFuture,
                  builder: (context, snapshot) {
                    final cameraController = controller;
                    if (cameraController == null ||
                        !cameraController.value.isInitialized) {
                      return Center(
                        child: SizedBox(
                          width: 26.w,
                          height: 26.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5.w,
                            color: AppColors.actionPrimary,
                          ),
                        ),
                      );
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _CameraPreviewCover(controller: cameraController),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: AppColors.bgPrimary,
                              width: 2.w,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewCover({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraSmallControl extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _CameraSmallControl({this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3C3C3C),
          border: Border.all(color: Colors.white, width: 1.5.w),
        ),
        child: Center(
          child: icon == null
              ? AppText(
                  label ?? '',
                  style: AppTextStyles.xs12Medium.copyWith(
                    color: AppColors.textInverse,
                    letterSpacing: 0,
                  ),
                )
              : Icon(icon, color: AppColors.iconInverse, size: 26.sp),
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _OutlinedActionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Center(
          child: AppText(
            text,
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

String _identityRoleFromArgs() {
  final args = Get.arguments;
  if (args is Map && args['role'] == 'trainer') {
    return 'trainer';
  }
  return 'member';
}

String _identityDocumentTypeFromArgs() {
  return _identityStringArg('documentType') ?? 'National ID Card';
}

String _identityIdCardNumberFromArgs() {
  return _identityStringArg('idCardNumber') ?? '';
}

String? _identityStringArg(String key) {
  final args = Get.arguments;
  if (args is Map && args[key] is String && (args[key] as String).isNotEmpty) {
    return args[key] as String;
  }
  return null;
}

IdentityCardSide _identitySideFromArgs() {
  final args = Get.arguments;
  if (args is Map && args['side'] == 'back') {
    return IdentityCardSide.back;
  }
  return IdentityCardSide.front;
}

Map<String, String>? _trainerRegisterDraftFromArgs() {
  final args = Get.arguments;
  if (args is! Map || args['trainerRegisterDraft'] is! Map) return null;

  final draft = args['trainerRegisterDraft'] as Map;
  return draft.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

Map<String, String>? _trainerRegisterDraftFromController() {
  if (!Get.isRegistered<TrainerRegisterController>()) return null;
  return Get.find<TrainerRegisterController>().identityVerificationDraft;
}

Map<String, String>? _memberRegisterDraftFromArgs() {
  final args = Get.arguments;
  if (args is! Map || args['memberRegisterDraft'] is! Map) return null;

  final draft = args['memberRegisterDraft'] as Map;
  return draft.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

Map<String, String>? _memberRegisterDraftFromController() {
  if (!Get.isRegistered<MemberRegisterController>()) return null;
  return Get.find<MemberRegisterController>().identityVerificationDraft;
}

String _backendIdCardType(String documentType) {
  final normalized = documentType.toLowerCase();
  if (normalized.contains('national')) return 'NID';
  if (normalized.contains('passport')) return 'PASSPORT';
  if (normalized.contains('driver')) return 'DRIVING_LICENSE';
  return documentType.trim().toUpperCase().replaceAll(' ', '_');
}

Map<String, dynamic> _identityArgs(
  String role,
  IdentityCardSide side, {
  String? documentType,
  String? idCardNumber,
  String? frontImagePath,
  String? backImagePath,
  String? capturedImagePath,
  Map<String, String>? trainerRegisterDraft,
  Map<String, String>? memberRegisterDraft,
}) {
  final args = <String, dynamic>{
    'role': role,
    'side': side == IdentityCardSide.back ? 'back' : 'front',
  };

  void addIfPresent(String key, String? value) {
    if (value != null && value.isNotEmpty) {
      args[key] = value;
    }
  }

  addIfPresent('documentType', documentType);
  addIfPresent('idCardNumber', idCardNumber);
  addIfPresent('frontImagePath', frontImagePath);
  addIfPresent('backImagePath', backImagePath);
  addIfPresent('capturedImagePath', capturedImagePath);
  if (trainerRegisterDraft != null) {
    args['trainerRegisterDraft'] = trainerRegisterDraft;
  }
  if (memberRegisterDraft != null) {
    args['memberRegisterDraft'] = memberRegisterDraft;
  }

  return args;
}
