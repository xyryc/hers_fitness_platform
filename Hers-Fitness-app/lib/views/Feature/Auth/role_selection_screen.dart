import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fitness/Helpers/route.dart';

import '../../Base/AppButton/appButton.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String selectedRole = 'Trainer'; // Default selection from screenshot

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
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: AppText(
                      'Are you a Member or\nTrainer?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.twoXL24Medium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.2,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role Cards
                  _buildRoleCard(
                    title: 'Member',
                    image: 'assets/images/member.png',
                    isSelected: selectedRole == 'Member',
                    onTap: () => setState(() => selectedRole = 'Member'),
                  ),
                  SizedBox(height: 16.h),
                  _buildRoleCard(
                    title: 'Trainer',
                    image: 'assets/images/trainer.png',
                    isSelected: selectedRole == 'Trainer',
                    onTap: () => setState(() => selectedRole = 'Trainer'),
                  ),

                  SizedBox(height: 32.h),

                  AppButton(
                    text: "Continue",
                    onTap: () {
                      if (selectedRole == 'Member') {
                        Get.toNamed(AppRoutes.memberSignUpScreen);
                      } else {
                        Get.toNamed(AppRoutes.trainerSignUpScreen);
                      }
                    },
                    showArrow: true,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String image,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: isSelected
              ? Border.all(color: AppColors.actionPrimary, width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Selection Indicator and Label
              Positioned(
                bottom: 20.h,
                left: 20.w,
                child: Row(
                  children: [
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 9.w,
                                height: 9.w,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    AppText(
                      title,
                      style: AppTextStyles.base16Medium.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
