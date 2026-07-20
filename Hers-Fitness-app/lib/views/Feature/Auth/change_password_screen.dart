import 'package:fitness/controllers/auth/password_recovery_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/AppColor/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final PasswordRecoveryController recoveryController;

  int strengthLevel = 0;

  @override
  void initState() {
    super.initState();
    recoveryController = Get.isRegistered<PasswordRecoveryController>()
        ? Get.find<PasswordRecoveryController>()
        : Get.put(PasswordRecoveryController());
    recoveryController.newPasswordController.addListener(
      _checkPasswordStrength,
    );
  }

  @override
  void dispose() {
    recoveryController.newPasswordController.removeListener(
      _checkPasswordStrength,
    );
    super.dispose();
  }

  void _checkPasswordStrength() {
    String text = recoveryController.newPasswordController.text;
    if (text.isEmpty) {
      if (strengthLevel != 0) setState(() => strengthLevel = 0);
    } else if (text.length <= 3) {
      if (strengthLevel != 1) setState(() => strengthLevel = 1);
    } else if (text.length <= 6) {
      if (strengthLevel != 2) setState(() => strengthLevel = 2);
    } else if (text.length <= 8) {
      if (strengthLevel != 3) setState(() => strengthLevel = 3);
    } else {
      if (strengthLevel != 4) setState(() => strengthLevel = 4);
    }
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
    if (strengthLevel == 0) return Colors.grey.shade300;
    if (strengthLevel == 1) return const Color(0xFFFA3A59); // Red
    if (strengthLevel == 2) return Colors.orange; // Yellow/Orange
    if (strengthLevel >= 3) return const Color(0xFF5BA71B); // Green
    return Colors.grey.shade300;
  }

  Widget _buildStrengthBars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildBar(1)),
            SizedBox(width: 8.w),
            Expanded(child: _buildBar(2)),
            SizedBox(width: 8.w),
            Expanded(child: _buildBar(3)),
            SizedBox(width: 8.w),
            Expanded(child: _buildBar(4)),
          ],
        ),
        if (strengthLevel > 0) ...[
          SizedBox(height: 8.h),
          AppText(
            getStrengthText(),
            style: AppTextStyles.sm14Regular.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBar(int barIndex) {
    bool isActive = strengthLevel >= barIndex;
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: isActive ? getStrengthColor(barIndex) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, -1.0),
                radius: 2.5,
                colors: [
                  const Color(0xFFFFA6B4).withValues(alpha: 0.5),
                  const Color(0xFFFFE0B9).withValues(alpha: 0.25),
                  Colors.white,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const CustomAppbar(title: "Change Password"),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.09),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "New Password",
                        style: AppTextStyles.base16Medium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        hintText: "******",
                        prefixIcon: "assets/icons/lock.svg",
                        controller: recoveryController.newPasswordController,
                        filColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        isPassword: true,
                      ),
                      SizedBox(height: 24.h),

                      AppText(
                        "Confirm Password",
                        style: AppTextStyles.base16Medium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        hintText: "******",
                        prefixIcon: "assets/icons/lock.svg",
                        controller:
                            recoveryController.confirmPasswordController,
                        filColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        isPassword: true,
                      ),
                      SizedBox(height: 16.h),

                      _buildStrengthBars(),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.045,
                      ),
                      Obx(
                        () => AppButton(
                          text: "Save Changes",
                          isLoading:
                              recoveryController.isResettingPassword.value,
                          onTap: recoveryController.isResettingPassword.value
                              ? () {}
                              : recoveryController.resetPassword,
                        ),
                      ),
                    ],
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
