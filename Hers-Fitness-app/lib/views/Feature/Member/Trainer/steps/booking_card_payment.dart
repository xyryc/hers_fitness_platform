import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../controllers/member/book_trainer_controller.dart';
import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';
import '../../../../Base/CustomTextfield/CustomTextfield.dart';

class BookingCardPayment extends StatelessWidget {
  final BookTrainerController controller;
  final VoidCallback onCheckout;

  const BookingCardPayment({
    super.key,
    required this.controller,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReservationBanner(controller: controller),
          SizedBox(height: 12.h),
          _PaymentCardPreview(controller: controller),
          SizedBox(height: 12.h),
          _label('Card Holder Name'),
          CustomTextField(
            controller: controller.cardHolderController,
            hintText: 'Name on card',
            contentPaddingVertical: 12.h,
            borderColor: AppColors.actionPrimary,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              size: 18.sp,
              color: AppColors.textTertiary,
            ),
          ),
          _label('Card Number'),
          CustomTextField(
            controller: controller.cardNumberController,
            hintText: 'Card number',
            contentPaddingVertical: 12.h,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(
              Icons.credit_card_rounded,
              size: 18.sp,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Exp', top: 0),
                    CustomTextField(
                      controller: controller.expController,
                      hintText: 'MM/YY',
                      contentPaddingVertical: 12.h,
                      prefixIcon: Icon(
                        Icons.credit_card_rounded,
                        size: 18.sp,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('CVC', top: 0),
                    CustomTextField(
                      controller: controller.cvcController,
                      hintText: 'CVC',
                      contentPaddingVertical: 12.h,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.credit_card_rounded,
                        size: 18.sp,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          GestureDetector(
            onTap: onCheckout,
            child: Container(
              height: 52.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.actionSecondary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Checkout',
                    style: AppTextStyles.xs12SemiBold.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: Colors.white,
                    size: 17.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {double? top}) {
    return Padding(
      padding: EdgeInsets.only(top: top ?? 10.h, bottom: 6.h),
      child: Text(
        text,
        style: AppTextStyles.xs12Medium.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ReservationBanner extends StatelessWidget {
  final BookTrainerController controller;

  const _ReservationBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.statusWarningSubtle,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFFBBF24)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.watch_later_rounded,
              size: 16.sp,
              color: AppColors.statusWarning,
            ),
            SizedBox(width: 8.w),
            Text(
              'Slot held for you : ${controller.holdCountdown} remaining',
              style: AppTextStyles.xs12Medium.copyWith(
                color: AppColors.statusWarning,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PaymentCardPreview extends StatelessWidget {
  final BookTrainerController controller;

  const _PaymentCardPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.cardHolderController,
        controller.cardNumberController,
        controller.expController,
      ]),
      builder: (context, _) {
        final holder = controller.cardHolderController.text.trim();
        final number = controller.cardNumberController.text.trim();
        final exp = controller.expController.text.trim();
        return Container(
          height: 142.h,
          width: double.infinity,
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.actionSecondary,
            borderRadius: BorderRadius.circular(14.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050505), Color(0xFF111827), Color(0xFF0EA5E9)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18.w,
                bottom: -22.h,
                child: Transform.rotate(
                  angle: -0.45,
                  child: Container(
                    width: 190.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFF59E0B),
                          Color(0xFF2563EB),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  'CARD',
                  style: AppTextStyles.base16Bold.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holder.isEmpty ? 'Name on card' : holder,
                      style: AppTextStyles.xxs9Medium.copyWith(
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _maskedNumber(number),
                      style: AppTextStyles.xs12SemiBold.copyWith(
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      exp.isEmpty ? 'Exp : MM/YY' : 'Exp : $exp',
                      style: AppTextStyles.xxs9Regular.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _maskedNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Card number';
    final lastFour = digits.length <= 4
        ? digits
        : digits.substring(digits.length - 4);
    return '**** **** **** $lastFour';
  }
}
