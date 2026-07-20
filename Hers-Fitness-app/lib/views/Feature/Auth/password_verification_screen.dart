import 'dart:math' as math;

import 'package:fitness/Helpers/route.dart';
import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/services/auth_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:fitness/utils/app_snackbar.dart';

class PasswordVerificationScreen extends StatefulWidget {
  const PasswordVerificationScreen({super.key});

  @override
  State<PasswordVerificationScreen> createState() =>
      _PasswordVerificationScreenState();
}

class _PasswordVerificationScreenState
    extends State<PasswordVerificationScreen> {
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();
  String code = '';
  bool isVerifying = false;
  bool isResending = false;

  Future<void> _verifyCode() async {
    final currentCode = code.trim();
    final email = _email;

    if (email.isEmpty) {
      showAppSnackbar(
        'Email missing',
        'Please go back and enter your email address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (currentCode.length != 6) {
      showAppSnackbar(
        'Invalid code',
        'Please enter the 6-digit code sent to your email.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      setState(() => isVerifying = true);

      if (_isForgotPasswordFlow) {
        final resetKey = await _authService.verifyPasswordResetOtp(
          email: email,
          otp: currentCode,
        );
        Get.toNamed(
          AppRoutes.changePasswordScreen,
          arguments: {'email': email, 'resetKey': resetKey},
        );
        return;
      }

      await _authService.verifyEmail(email: email, code: currentCode);

      if (_nextRoute.isNotEmpty) {
        final hasSession = await _ensureSessionAfterSignup(email);
        if (hasSession) {
          Get.offAllNamed(_nextRoute);
        } else {
          showAppSnackbar(
            'Email verified',
            'Please sign in to continue.',
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAllNamed(AppRoutes.signInScreen);
        }
        return;
      }

      Get.offNamed(AppRoutes.verifyIdentityScreen, arguments: _identityArgs);
    } on ApiException catch (error) {
      showAppSnackbar(
        'Verification failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Verification failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    final email = _email;
    if (email.isEmpty) {
      showAppSnackbar(
        'Email missing',
        'Please go back and enter your email address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      setState(() => isResending = true);
      if (_isForgotPasswordFlow) {
        await _authService.forgotPassword(email: email);
      } else {
        await _authService.resendVerification(email: email);
      }

      showAppSnackbar(
        'Code sent',
        'Please check your email for the latest verification code.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      showAppSnackbar(
        'Resend failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Resend failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => isResending = false);
      }
    }
  }

  bool get _isForgotPasswordFlow => _flow == 'forgotPassword';

  String get _flow {
    final args = Get.arguments;
    if (args is Map && args['flow'] is String) {
      return args['flow'] as String;
    }
    return 'signup';
  }

  String get _role {
    final args = Get.arguments;
    if (args is Map && args['role'] == 'trainer') {
      return 'trainer';
    }
    return 'member';
  }

  String get _email {
    final args = Get.arguments;
    if (args is Map && args['email'] is String) {
      return (args['email'] as String).trim();
    }
    return '';
  }

  String get _password {
    final args = Get.arguments;
    if (args is Map && args['password'] is String) {
      return args['password'] as String;
    }
    return '';
  }

  String get _title {
    if (_isForgotPasswordFlow) {
      return 'Password Reset Sent';
    }
    return 'Email Verification';
  }

  String get _maskedEmail {
    final email = _email;
    final atIndex = email.indexOf('@');

    if (email.isEmpty || atIndex <= 1) {
      return 'your email';
    }

    final name = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    final visibleLength = name.length < 5 ? name.length : 5;
    final visibleName = name.length <= 3
        ? name[0]
        : name.substring(0, visibleLength);
    return '$visibleName***$domain';
  }

  String get _backLabel {
    final args = Get.arguments;
    if (args is Map && args['backLabel'] is String) {
      return args['backLabel'] as String;
    }

    if (_isForgotPasswordFlow) {
      return 'Back to Login';
    }
    return 'Back to Sign up';
  }

  String get _nextRoute {
    final args = Get.arguments;
    if (args is Map && args['nextRoute'] is String) {
      return args['nextRoute'] as String;
    }
    return '';
  }

  Map<String, dynamic> get _identityArgs {
    final args = Get.arguments;
    final identityArgs = <String, dynamic>{'role': _role};

    if (args is Map && args['trainerRegisterDraft'] is Map) {
      identityArgs['trainerRegisterDraft'] = args['trainerRegisterDraft'];
    }
    if (args is Map && args['memberRegisterDraft'] is Map) {
      identityArgs['memberRegisterDraft'] = args['memberRegisterDraft'];
    }

    return identityArgs;
  }

  Future<bool> _ensureSessionAfterSignup(String email) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      return true;
    }

    final password = _password;
    if (!_isForgotPasswordFlow && email.isNotEmpty && password.isNotEmpty) {
      try {
        await _authService.signIn(username: email, password: password);
        return true;
      } catch (error) {
        debugPrint('Auto sign in after email verification failed: $error');
      }
    }

    return false;
  }

  void _backToPreviousFlow() {
    if (_isForgotPasswordFlow) {
      Get.offAllNamed(AppRoutes.signInScreen);
      return;
    }

    Get.back();
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
                  const Color(0xFFFFA6B4).withValues(alpha: 0.32),
                  const Color(0xFFFFE0B9).withValues(alpha: 0.18),
                  Colors.white,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomAppbar(),
                  SizedBox(height: 26.h),
                  const _EmailCodeIllustration(),
                  SizedBox(height: 28.h),
                  AppText(
                    _title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.base16SemiBold.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: AppText(
                      "Please check your email in a few minutes We've sent a 6-digit code to $_maskedEmail",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: const Color(0xFF4B5563),
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    backgroundColor: Colors.transparent,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textStyle: AppTextStyles.sm14SemiBold.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(6.r),
                      fieldHeight: 44.h,
                      fieldWidth: 36.w,
                      activeFillColor: const Color(0xFFFFF3F5),
                      inactiveFillColor: const Color(0xFFFFF3F5),
                      selectedFillColor: Colors.white,
                      activeColor: const Color(0xFFFFE2E8),
                      inactiveColor: const Color(0xFFFFE2E8),
                      selectedColor: AppColors.actionPrimary,
                      borderWidth: 1,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    onCompleted: (value) => code = value,
                    onChanged: (value) => code = value,
                    beforeTextPaste: (_) => true,
                  ),
                  SizedBox(height: 18.h),
                  AppButton(
                    text: 'Verify',
                    height: 48.h,
                    borderRadius: 6.r,
                    isLoading: isVerifying,
                    onTap: isVerifying ? () {} : _verifyCode,
                  ),
                  SizedBox(height: 22.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        "Didn't receive the code? ",
                        style: AppTextStyles.xs12Regular.copyWith(
                          color: const Color(0xFF4B5563),
                          letterSpacing: 0,
                        ),
                      ),
                      GestureDetector(
                        onTap: isResending ? null : _resendCode,
                        child: AppText(
                          isResending ? 'Sending...' : 'Resend',
                          style: AppTextStyles.xs12Medium.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: _backToPreviousFlow,
                    child: AppText(
                      _backLabel,
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
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
}

class _EmailCodeIllustration extends StatelessWidget {
  const _EmailCodeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176.w,
      height: 150.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 6.h,
            child: Container(
              width: 130.w,
              height: 24.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28.r,
                    spreadRadius: 2.r,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20.h,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 66.w,
                height: 66.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE36A), Color(0xFFFFB21B)],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                width: 156.w,
                height: 92.h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFD749), Color(0xFFFFA91F)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12.h,
            child: ClipPath(
              clipper: _EnvelopeFrontClipper(),
              child: Container(
                width: 156.w,
                height: 92.h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC829), Color(0xFFF59E0B)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 38.h,
            child: Container(
              width: 86.w,
              height: 86.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.25, -0.35),
                  radius: 0.9,
                  colors: [
                    Color(0xFFBDE8FF),
                    Color(0xFF58A9FF),
                    Color(0xFF346CF6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.alternate_email_rounded,
                color: const Color(0xFF1D4ED8),
                size: 52.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeFrontClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
