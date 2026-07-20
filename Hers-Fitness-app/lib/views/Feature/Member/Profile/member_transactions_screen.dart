import 'package:fitness/controllers/member/member_profile_controller.dart';
import 'package:fitness/models/transaction_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MemberTransactionsScreen extends StatefulWidget {
  const MemberTransactionsScreen({super.key});

  @override
  State<MemberTransactionsScreen> createState() =>
      _MemberTransactionsScreenState();
}

class _MemberTransactionsScreenState extends State<MemberTransactionsScreen> {
  late final MemberProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MemberProfileController>()
        ? Get.find<MemberProfileController>()
        : Get.put(MemberProfileController());
    _controller.fetchTransactions(showError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingTransactions.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                );
              }
              final list = _controller.transactions;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64.w,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16.h),
                      AppText(
                        "No transactions yet",
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.actionPrimary,
                onRefresh: () => _controller.fetchTransactions(showError: true),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) => _TransactionCard(item: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AppText(
                "Transactions",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});
  final TransactionModel item;

  @override
  Widget build(BuildContext context) {
    final isPaid = item.status.toUpperCase() == 'PAID';
    final dateStr = item.paidAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(item.paidAt!.toLocal())
        : item.createdAt != null
        ? DateFormat('MMM d, yyyy').format(item.createdAt!.toLocal())
        : '—';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.actionPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: AppColors.actionPrimary,
              size: 22.w,
            ),
          ),
          SizedBox(width: 14.w),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.className ?? 'Class Booking',
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.trainerName != null) ...[
                  SizedBox(height: 2.h),
                  AppText(
                    item.trainerName!,
                    style: AppTextStyles.sm14Regular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                AppText(
                  dateStr,
                  style: AppTextStyles.sm14Regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
                if (item.couponCode != null) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: AppText(
                      '🏷 ${item.couponCode}',
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${item.currency} ${item.totalAmount}',
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText(
                  item.status,
                  style: AppTextStyles.sm14Regular.copyWith(
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
