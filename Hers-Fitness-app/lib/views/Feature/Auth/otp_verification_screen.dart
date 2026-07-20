import 'package:fitness/controllers/auth/password_recovery_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../utils/AppColor/app_colors.dart';
import 'package:fitness/Helpers/route.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recoveryController = Get.isRegistered<PasswordRecoveryController>()
        ? Get.find<PasswordRecoveryController>()
        : Get.put(PasswordRecoveryController());

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
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const CustomAppbar(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                AppText(
                  "Password Reset Sent",
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: AppText(
                    "Please check your email in a few minutes We've sent a 6-digit code to hello***@gmail.com",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.base16Medium.copyWith(
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 48.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    backgroundColor: Colors.transparent,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    textStyle: AppTextStyles.twoXL24Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56.w,
                      fieldWidth: 50.w,
                      activeFillColor: const Color(0xFFFDE1E5),
                      inactiveFillColor: const Color(0xFFFDE1E5),
                      selectedFillColor: const Color(0xFFFDE1E5),
                      activeColor: const Color(0xFFF2C6CC),
                      inactiveColor: const Color(0xFFF2C6CC),
                      selectedColor: AppColors.actionPrimary,
                      borderWidth: 1,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    onCompleted: (value) {
                      recoveryController.code.value = value;
                    },
                    onChanged: (value) {
                      recoveryController.code.value = value;
                    },
                    beforeTextPaste: (text) {
                      return true;
                    },
                  ),
                ),
                SizedBox(height: 32.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Obx(
                    () => AppButton(
                      text: "Verify",
                      isLoading: recoveryController.isVerifyingCode.value,
                      onTap: recoveryController.isVerifyingCode.value
                          ? () {}
                          : recoveryController.verifyEmailCode,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      "Didn't receive the code? ",
                      style: AppTextStyles.base16Medium.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: AppText(
                        "Resend",
                        style: AppTextStyles.base16Medium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () {
                    Get.offAllNamed(AppRoutes.signInScreen);
                  },
                  child: AppText(
                    "Back to Login",
                    style: AppTextStyles.base16Medium.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
