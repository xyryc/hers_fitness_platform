import 'package:fitness/controllers/member/book_trainer_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'steps/booking_payment.dart';
import 'steps/booking_personal_info.dart';
import 'steps/booking_session_select.dart';

class BookTrainerScreen extends StatefulWidget {
  const BookTrainerScreen({super.key});

  @override
  State<BookTrainerScreen> createState() => _BookTrainerScreenState();
}

class _BookTrainerScreenState extends State<BookTrainerScreen> {
  late final BookTrainerController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BookTrainerController>()) {
      Get.delete<BookTrainerController>(force: true);
    }
    controller = Get.put(BookTrainerController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<BookTrainerController>()) {
      Get.delete<BookTrainerController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const Color(0xFFFFA6B4).withValues(alpha: 0.24),
                  const Color(0xFFFFE0B9).withValues(alpha: 0.12),
                  Colors.white,
                ],
                stops: const [0.0, 0.72, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 14.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomAppbar(
                    title: 'Book Trainer',
                    onTap: controller.previousStep,
                  ),
                ),
                SizedBox(height: 20.h),
                _ProgressIndicator(controller: controller),
                SizedBox(height: 22.h),
                Expanded(
                  child: Obx(
                    () => IndexedStack(
                      index: controller.currentStep.value - 1,
                      children: [
                        BookingSessionSelect(controller: controller),
                        BookingPersonalInfo(controller: controller),
                        BookingPayment(
                          controller: controller,
                          onSelectPaymentMethod: () =>
                              _showPaymentMethodSheet(controller),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BottomButton(controller: controller),
        ],
      ),
    );
  }

  void _showPaymentMethodSheet(BookTrainerController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderPrimary,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Select Payment Methods',
                style: AppTextStyles.xs12SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 20.h),
              _PaymentMethodTile(
                title: 'Stripe',
                trailing: 'stripe',
                onTap: () => controller.setPaymentMethod('Stripe'),
              ),
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.actionSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Select',
                    style: AppTextStyles.xs12SemiBold.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final BookTrainerController controller;

  const _ProgressIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentStep = controller.currentStep.value;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        child: Row(
          children: [
            _circle(step: 1, currentStep: currentStep),
            _line(active: currentStep >= 2),
            _circle(step: 2, currentStep: currentStep),
            _line(active: currentStep >= 3),
            _circle(step: 3, currentStep: currentStep),
          ],
        ),
      );
    });
  }

  Widget _circle({required int step, required int currentStep}) {
    bool isActive = step == currentStep;
    bool isReached = step < currentStep || step == currentStep + 1;

    Color borderColor;
    Color bgColor;
    Color dotColor;

    if (isActive) {
      borderColor = AppColors.actionPrimary;
      bgColor = AppColors.actionPrimary;
      dotColor = Colors.white;
    } else if (isReached) {
      borderColor = AppColors.actionPrimary;
      bgColor = Colors.white;
      dotColor = AppColors.actionPrimary;
    } else {
      borderColor = AppColors.borderPrimary;
      bgColor = Colors.white;
      dotColor = AppColors.borderPrimary;
    }

    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2.w),
      ),
      child: Center(
        child: Container(
          width: 5.w,
          height: 5.w,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _line({required bool active}) {
    return Expanded(
      child: Container(
        height: 1.h,
        color: active ? AppColors.actionPrimary : const Color(0xFFF2F2F2),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final BookTrainerController controller;

  const _BottomButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPaymentSummary = controller.currentStep.value == 3;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12.r,
                offset: Offset(0, -5.h),
              ),
            ],
          ),
          child: isPaymentSummary
              ? _paymentBottom()
              : _continueButton(
                  text: controller.currentStep.value == 2
                      ? 'Reserve & Continue'
                      : 'Continue',
                  icon: Icons.arrow_forward,
                ),
        ),
      );
    });
  }

  Widget _continueButton({required String text, required IconData icon}) {
    return Obx(() {
      final loading = controller.isSubmitting.value;
      return GestureDetector(
        onTap: loading ? null : () => controller.nextStep(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.actionSecondary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Text(
                  text,
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(icon, color: Colors.white, size: 20.sp),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _paymentBottom() {
    return Container(
      height: 66.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.actionSecondary,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.priceText(controller.total),
                  style: AppTextStyles.sm14SemiBold.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Total Price',
                  style: AppTextStyles.xxs9Regular.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final loading = controller.isSubmitting.value;
            return GestureDetector(
              onTap: loading ? null : () => controller.nextStep(),
              child: Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                decoration: BoxDecoration(
                  color: AppColors.actionPrimary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    if (loading)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Text(
                        'Pay now',
                        style: AppTextStyles.xs12SemiBold.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.shopping_cart_checkout_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.xs12Medium.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              trailing,
              style: AppTextStyles.xs12SemiBold.copyWith(
                color: trailing.toLowerCase().contains('stripe')
                    ? const Color(0xFF635BFF)
                    : AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
