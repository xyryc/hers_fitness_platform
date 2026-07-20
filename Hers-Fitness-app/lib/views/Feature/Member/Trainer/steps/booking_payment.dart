import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../controllers/member/book_trainer_controller.dart';
import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';
import '../../../../Base/CustomTextfield/CustomTextfield.dart';
import '../widgets/booking_trainer_summary.dart';

class BookingPayment extends StatelessWidget {
  final BookTrainerController controller;
  final VoidCallback onSelectPaymentMethod;

  const BookingPayment({
    super.key,
    required this.controller,
    required this.onSelectPaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 110.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12.h),
          BookingTrainerSummary(
            controller: controller,
            showChevron: false,
            margin: EdgeInsets.only(bottom: 10.h),
          ),
          Obx(() {
            if (controller.holdRemainingSeconds.value <= 0) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.statusWarningSubtle,
                borderRadius: BorderRadius.circular(10.r),
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
                    'Reserved for ${controller.holdCountdown}',
                    style: AppTextStyles.xs12Medium.copyWith(
                      color: AppColors.statusWarning,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(
            () => _summaryRow(
              Icons.calendar_month_outlined,
              controller.selectedDatesTimes,
              action: 'Change',
            ),
          ),
          Obx(
            () => _summaryRow(
              Icons.location_on_outlined,
              controller.summaryLocation,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Enter Coupon',
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.couponController,
                  hintText: 'Coupon code',
                  contentPaddingVertical: 12.h,
                  prefixIcon: Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.textTertiary,
                    size: 18.sp,
                  ),
                  borderColor: AppColors.borderPrimary,
                ),
              ),
              SizedBox(width: 10.w),
              _smallButton('Add', () {}),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Payment Methods',
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onSelectPaymentMethod,
            child: Container(
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      controller.selectedPaymentMethod.value.toLowerCase(),
                      style: AppTextStyles.sm14SemiBold.copyWith(
                        color: const Color(0xFF635BFF),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 22.sp),
                ],
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Payment Detail',
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => _paymentRow(
              'Per Member',
              controller.priceText(controller.trainingPrice),
            ),
          ),
          Obx(
            () => _paymentRow(
              'Subtotal',
              controller.priceText(
                controller.subtotal > 0
                    ? controller.subtotal
                    : controller.trainingPrice *
                          controller.selectedSlotIds.length,
              ),
            ),
          ),
          if (controller.hasDiscount)
            _paymentRow(
              'Discount',
              controller.priceText(controller.discount),
              muted: true,
            ),
          if (controller.hasTax)
            _paymentRow(
              'Tax',
              controller.priceText(controller.tax),
              muted: true,
            ),
          SizedBox(height: 10.h),
          Divider(color: AppColors.borderPrimary, height: 1.h),
          SizedBox(height: 10.h),
          Obx(
            () => _paymentRow(
              'Total',
              controller.priceText(controller.total),
              total: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, {String? action}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textTertiary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.xxs9Medium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
          if (action != null)
            Text(
              action,
              style: AppTextStyles.xxs9Medium.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58.w,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.actionSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          text,
          style: AppTextStyles.xs12Medium.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    bool muted = false,
    bool total = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  (total
                          ? AppTextStyles.sm14SemiBold
                          : AppTextStyles.xs12Regular)
                      .copyWith(
                        color: muted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
            ),
          ),
          Text(
            value,
            style:
                (total ? AppTextStyles.sm14SemiBold : AppTextStyles.xs12Regular)
                    .copyWith(color: AppColors.textPrimary, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
