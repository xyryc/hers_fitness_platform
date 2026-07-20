import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/auth/sign_in_controller.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../../utils/AppColor/app_colors.dart';
import '../../../utils/AppTextStyle/app_text_styles.dart';
import '../../Base/CustomTextfield/CustomTextfield.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final SignInController signInController;

  @override
  void initState() {
    super.initState();
    signInController = Get.isRegistered<SignInController>()
        ? Get.find<SignInController>()
        : Get.put(SignInController());
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
                center: Alignment(1.0, -1.0),
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

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.07,
                        ),

                        Image.asset(
                          "assets/images/splashImg.png",
                          width: 180.w,
                          height: 100.h,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.065,
                        ),

                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.bgPrimary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.actionPrimary,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 18.h),
                                  AppText(
                                    "E-mail",
                                    style: AppTextStyles.base16Medium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),

                                  CustomTextField(
                                    hintText: 'Enter your E-mail',
                                    controller:
                                        signInController.emailController,
                                    filColor: AppColors.bgPrimary,
                                    borderColor: AppColors.actionPrimary,
                                    prefixIcon: "assets/icons/emailIcon.svg",
                                  ),
                                  SizedBox(height: 18.h),

                                  AppText(
                                    "Password",
                                    style: AppTextStyles.base16Medium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),

                                  CustomTextField(
                                    hintText: 'Enter your password',
                                    controller:
                                        signInController.passwordController,
                                    filColor: AppColors.bgPrimary,
                                    borderColor: AppColors.actionPrimary,
                                    prefixIcon: "assets/icons/lock.svg",
                                    isPassword: true,
                                  ),
                                  SizedBox(height: 18.h),

                                  Row(
                                    children: [
                                      Obx(
                                        () => GestureDetector(
                                          onTap:
                                              signInController.toggleRememberMe,
                                          child: Container(
                                            height: 18.h,
                                            width: 18.w,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.actionPrimary,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color:
                                                  signInController
                                                      .rememberMe
                                                      .value
                                                  ? AppColors.actionPrimary
                                                  : Colors.white,
                                            ),
                                            child:
                                                signInController
                                                    .rememberMe
                                                    .value
                                                ? Center(
                                                    child: SvgPicture.asset(
                                                      "assets/icons/checkIcon.svg",
                                                      height: 12.h,
                                                      width: 12.w,
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            Colors.white,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),

                                      AppText(
                                        'Remember me',
                                        style: AppTextStyles.sm14Medium
                                            .copyWith(color: Color(0xFF798090)),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          Get.toNamed(
                                            AppRoutes.forgotPasswordScreen,
                                          );
                                        },
                                        child: AppText(
                                          'Forgot Password?',
                                          style: AppTextStyles.sm14Medium
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.040,
                                  ),

                                  Obx(
                                    () => AppButton(
                                      text: "Sign In",
                                      isLoading:
                                          signInController.isLoading.value,
                                      onTap: signInController.isLoading.value
                                          ? () {}
                                          : signInController.signIn,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.040,
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          thickness: 1.5,
                                          color: Color(0xFFB1B1B1),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                        ),
                                        child: Text(
                                          "Or Sing In With",
                                          style: AppTextStyles.sm14Medium
                                              .copyWith(
                                                color: Color(0xFF303030),
                                              ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          thickness: 1.5,
                                          color: Color(0xFFB1B1B1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.030,
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Button
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0B0E12,
                                              ).withValues(alpha: 0.20),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          onPressed: () {},
                                          icon: SvgPicture.asset(
                                            "assets/icons/googleIcon.svg",
                                            width: 24,
                                            height: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),

                                      // apple Button
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0B0E12,
                                              ).withValues(alpha: 0.20),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          onPressed: () {},
                                          icon: SvgPicture.asset(
                                            "assets/icons/appleIcon.svg",
                                            width: 28,
                                            height: 28,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Facebook Button
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0B0E12,
                                              ).withValues(alpha: 0.20),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          onPressed: () {},
                                          icon: SvgPicture.asset(
                                            "assets/icons/fbIcon.svg",
                                            width: 28,
                                            height: 28,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.030,
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppText(
                                        "Don’t have an account? ",
                                        style: AppTextStyles.sm14Regular
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Get.toNamed(
                                            AppRoutes.roleSelectionScreen,
                                          );
                                        },
                                        child: AppText(
                                          "Create account",
                                          style: AppTextStyles.sm14SemiBold
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.05,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ), // Ends Expanded Container
                      ],
                    ), // Ends inner Column
                  ), // Ends IntrinsicHeight
                ), // Ends ConstrainedBox
              );
            },
          ), // Ends LayoutBuilder
        ],
      ),
    );
  }
}
