import 'package:fitness/Helpers/route.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/AppColor/app_colors.dart';
import 'package:get/get.dart';
import '../../../../utils/AppTextStyle/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.0, -1.0),
                radius: 1.8,
                colors: [
                  Color(0xFFE06F83),
                  Color(0xFFF7869A),
                  Color(0xFFFFA6B4),
                  Color(0xFFFFE0B9),
                  Colors.white,
                ],
                stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
          ),

          // Background Image (Dumbbells)
          Positioned.fill(
            top: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/welcomeBg.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                AppText(
                  'Welcome to',
                  style: AppTextStyles.fourXL30Bold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Image.asset('assets/images/welcomeLogo.png', width: 250),
                const Spacer(),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFE06F83),
                              Color(0xFFF093A3),
                              Color(0xFFE06F83),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSecondary,
                            width: 1.5,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.signInScreen);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: AppText(
                            'Sign In',
                            style: AppTextStyles.base16Bold.copyWith(
                              color: AppColors.textInverse,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.borderPrimary,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset("assets/icons/googleIcon.svg"),
                              const SizedBox(width: 8),
                              Text(
                                'Sign In With Google',
                                style: AppTextStyles.base16Bold.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            "Don’t have an account? ",
                            style: AppTextStyles.sm14SemiBold.copyWith(
                              color: AppColors.textInverse,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.roleSelectionScreen);
                            },
                            child: Text(
                              'Sign Up',
                              style: AppTextStyles.sm14SemiBold.copyWith(
                                color: AppColors.actionPrimary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.actionPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.080,
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
