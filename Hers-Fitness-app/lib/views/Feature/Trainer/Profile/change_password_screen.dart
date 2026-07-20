import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final TrainerProfileController _profileController;

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  int strengthLevel = 0;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<TrainerProfileController>()
        ? Get.find<TrainerProfileController>()
        : Get.put(TrainerProfileController());

    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.removeListener(_checkPasswordStrength);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String text = _newPasswordController.text;
    setState(() {
      if (text.isEmpty) {
        strengthLevel = 0;
      } else if (text.length <= 3) {
        strengthLevel = 1;
      } else if (text.length <= 6) {
        strengthLevel = 2;
      } else if (text.length <= 8) {
        strengthLevel = 3;
      } else {
        strengthLevel = 4;
      }
    });
  }

  String getStrengthText() {
    switch (strengthLevel) {
      case 1:
        return "Weak password! Let's add more strength!";
      case 2:
        return "Good password! Try a mix of characters!";
      case 3:
      case 4:
        return "Amazing strength! Let's continue!";
      default:
        return "";
    }
  }

  Color getStrengthColor(int level) {
    if (strengthLevel == 0) return Colors.grey.shade200;
    if (strengthLevel == 1) return const Color(0xFFFA3A59); // Red
    if (strengthLevel == 2) return Colors.orange; // Yellow/Orange
    if (strengthLevel >= 3) return const Color(0xFF5BA71B); // Green
    return Colors.grey.shade200;
  }

  Widget _buildBar(int barIndex) {
    bool isActive = strengthLevel >= barIndex;
    return Expanded(
      child: Container(
        height: 4.h,
        margin: EdgeInsets.only(right: barIndex == 4 ? 0 : 8.w),
        decoration: BoxDecoration(
          color: isActive ? getStrengthColor(barIndex) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  Future<void> _submitChangePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showAppSnackbar(
        'Missing information',
        'Please fill all password fields.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showAppSnackbar(
        'Password mismatch',
        'New password and confirm password do not match.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _profileController.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmPassword,
    );

    if (!success || !mounted) return;

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Current Password"),
                  CustomTextField(
                    controller: _currentPasswordController,
                    hintText: "******",
                    isPassword: _currentObscure,
                    prefixIcon: "assets/icons/lock.svg",
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _currentObscure = !_currentObscure),
                      child: Icon(
                        _currentObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20.w,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  _buildLabel("New Password"),
                  CustomTextField(
                    controller: _newPasswordController,
                    hintText: "******",
                    isPassword: _newObscure,
                    prefixIcon: "assets/icons/lock.svg",
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _newObscure = !_newObscure),
                      child: Icon(
                        _newObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20.w,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  _buildLabel("Confirm Password"),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: "******",
                    isPassword: _confirmObscure,
                    prefixIcon: "assets/icons/lock.svg",
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _confirmObscure = !_confirmObscure),
                      child: Icon(
                        _confirmObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20.w,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _buildPasswordStrength(),
                  if (strengthLevel > 0) ...[
                    SizedBox(height: 12.h),
                    AppText(
                      getStrengthText(),
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  SizedBox(height: 40.h),
                  Obx(
                    () => AppButton(
                      isLoading: _profileController.isChangingPassword.value,
                      onTap: _profileController.isChangingPassword.value
                          ? () {}
                          : _submitChangePassword,
                      text: 'Save Changes',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AppText(
                "Change Password",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AppText(
        text,
        style: AppTextStyles.base16SemiBold.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15.sp,
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    return Row(
      children: [_buildBar(1), _buildBar(2), _buildBar(3), _buildBar(4)],
    );
  }
}
