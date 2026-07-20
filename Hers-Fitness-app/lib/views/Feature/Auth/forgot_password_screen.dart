import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../Helpers/route.dart';
import '../../../utils/AppColor/app_colors.dart';
import '../../Base/CustomAppbar/custom_appbar.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background Gradient
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.045),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const CustomAppbar(),
              ),
              SizedBox(height: 32.h),

              // Titles
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppText(
                  "Forgot Password",
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppText(
                  "Please select the following options to\nreset your password.",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Options
              _buildOptionCard(
                title: "Send via Email",
                icon: Icons.email_outlined,
                iconColor: const Color(0xFFF97316),
                onTap: () {
                  Get.toNamed(AppRoutes.resetPasswordEmailScreen);
                },
              ),
              SizedBox(height: 16.h),
              _buildOptionCard(
                title: "Send via mobile",
                icon: Icons.phone_iphone_outlined,
                iconColor: AppColors.actionPrimary,
                onTap: () {
                  Get.toNamed(AppRoutes.otpVerificationScreen);
                },
              ),

              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      // Bottom Floor Shadow
                      Positioned(
                        bottom: -5,
                        left: 60.w,
                        right: 60.w,
                        child: Container(
                          height: 20.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Actual barbell image
                      Image.asset("assets/images/forgotscreenImg.png"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  color: iconColor.withValues(alpha: 0.05),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppText(
                  title,
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
