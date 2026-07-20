import 'dart:io';

import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/models/trainer_earnings_model.dart';
import 'package:fitness/models/trainer_top_class_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../Helpers/route.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  int selectedYear = DateTime.now().year;
  String selectedPeriod = "Monthly"; // default matches API default

  late final TrainerProfileController _ctrl;
  final RxDouble _scrollOffset = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<TrainerProfileController>()
        ? Get.find<TrainerProfileController>()
        : Get.put(TrainerProfileController());
  }

  // ── Period tab change ─────────────────────────────────────────────────────

  void _onPeriodChanged(String period) {
    setState(() => selectedPeriod = period);
    switch (period) {
      case 'Weekly':
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        _ctrl.fetchEarnings(period: 'weekly', date: dateStr);
        break;
      case 'Yearly':
        _ctrl.fetchEarnings(period: 'yearly');
        break;
      case 'Monthly':
      default:
        _ctrl.fetchEarnings(period: 'monthly', year: selectedYear);
        break;
    }
  }

  void _onYearChanged(int year) {
    setState(() => selectedYear = year);
    if (selectedPeriod == 'Monthly') {
      _ctrl.fetchEarnings(period: 'monthly', year: year);
    }
  }

  // ── Year picker dialog ────────────────────────────────────────────────────

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Year"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(DateTime.now().year - 10),
            lastDate: DateTime(DateTime.now().year + 10),
            selectedDate: DateTime(selectedYear),
            onChanged: (DateTime dt) {
              Navigator.pop(context);
              _onYearChanged(dt.year);
            },
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _scrollOffset.value = notification.metrics.pixels;
              }
              return false;
            },
            child: Obx(
              () => RefreshIndicator(
                color: AppColors.actionPrimary,
                onRefresh: () async {
                  await Future.wait([
                    _ctrl.fetchProfile(showError: true),
                    _ctrl.fetchDashboardStats(showError: true),
                    _ctrl.fetchEarnings(
                      period: selectedPeriod.toLowerCase(),
                      year: selectedPeriod == 'Monthly' ? selectedYear : null,
                    ),
                    _ctrl.fetchTopClasses(showError: true),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      if (_ctrl.isLoading.value)
                        LinearProgressIndicator(color: AppColors.actionPrimary),
                      if (!_ctrl.payoutReady)
                        _PayoutBanner(
                          onTap: () =>
                              Get.toNamed(AppRoutes.trainerPayoutScreen),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            SizedBox(height: 12.h),
                            // Name
                            AppText(
                              _ctrl.displayName,
                              style: AppTextStyles.xl20SemiBold.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 4.w),
                                AppText(
                                  _ctrl.displayLocation,
                                  style: AppTextStyles.sm14Medium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),

                            // ── Stats Grid ──────────────────────────────────────
                            _buildStatsGrid(),
                            SizedBox(height: 24.h),

                            // ── Earnings Overview ───────────────────────────────
                            _buildEarningsOverview(context),
                            SizedBox(height: 32.h),

                            // ── Top Performing Classes ──────────────────────────
                            Row(
                              children: [
                                AppText(
                                  "Top Performing Classes",
                                  style: AppTextStyles.base16SemiBold.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildTopClasses(),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dynamic Status Bar Background
          Obx(() {
            final opacity = (_scrollOffset.value / 60).clamp(0.0, 1.0);
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top,
                color: AppColors.bgPrimary.withValues(alpha: opacity),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 235.h,
      child: Stack(
        children: [
          // Cover photo
          Obx(
            () => Container(
              height: 190.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                image: DecorationImage(
                  image: _ctrl.coverPhotoUrl.value.isEmpty
                      ? const NetworkImage(
                              "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=600&auto=format&fit=crop",
                            )
                            as ImageProvider
                      : _ctrl.coverPhotoUrl.value.startsWith('http')
                      ? NetworkImage(_ctrl.coverPhotoUrl.value)
                      : FileImage(File(_ctrl.coverPhotoUrl.value)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Camera button
          Positioned(
            top: 140.h,
            right: 30.w,
            child: GestureDetector(
              onTap: _ctrl.pickCoverPhoto,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            ),
          ),
          // Back + Settings
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Get.back(),
                ),
                _HeaderCircleButton(
                  icon: Icons.settings_outlined,
                  onTap: () => Get.toNamed(AppRoutes.accountSettingsScreen),
                ),
              ],
            ),
          ),
          // Profile image
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(() {
              final imageUrl = _ctrl.profileImageUrl;
              return Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white, width: 4),
                  image: imageUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: imageUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 40.w,
                      )
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return Obx(() {
      final loading = _ctrl.isLoadingStats.value;
      return GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 1.4,
        children: [
          _ProfileStatCard(
            title: "Total Classes",
            value: loading ? '…' : _ctrl.totalClasses,
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFFF7869A),
          ),
          _ProfileStatCard(
            title: "Total Revenue",
            value: loading ? '…' : _ctrl.totalRevenue,
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFF16A34A),
          ),
          _ProfileStatCard(
            title: "Total Attendance",
            value: loading ? '…' : _ctrl.totalAttendance,
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF0284C7),
          ),
          _ProfileStatCard(
            title: "Avg Class Size",
            value: loading ? '…' : _ctrl.avgClassSize,
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFF7869A),
          ),
        ],
      );
    });
  }

  // ── Earnings Overview ─────────────────────────────────────────────────────

  Widget _buildEarningsOverview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + year picker (monthly only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "Earnings Overview",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (selectedPeriod == "Monthly")
                GestureDetector(
                  onTap: () => _showYearPicker(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8.w),
                        AppText(
                          "$selectedYear",
                          style: AppTextStyles.xs12Regular.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          // Total earnings label
          Obx(() {
            final e = _ctrl.earnings.value;
            if (e == null) return const SizedBox.shrink();
            return AppText(
              NumberFormat.currency(
                symbol: '\$',
                decimalDigits: 2,
              ).format(e.totalEarnings),
              style: AppTextStyles.xl20SemiBold.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22.sp,
              ),
            );
          }),
          SizedBox(height: 16.h),
          // Period tabs
          Row(
            children: ["Weekly", "Monthly", "Yearly"].map((period) {
              final isSelected = selectedPeriod == period;
              return GestureDetector(
                onTap: () => _onPeriodChanged(period),
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.actionPrimary
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: AppText(
                    period,
                    style: AppTextStyles.xs12Medium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          // Chart
          Obx(() {
            if (_ctrl.isLoadingEarnings.value) {
              return SizedBox(
                height: 200.h,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                ),
              );
            }
            final data = _ctrl.earnings.value;
            if (data == null || data.data.isEmpty) {
              return SizedBox(
                height: 200.h,
                child: Center(
                  child: AppText(
                    "No earnings data",
                    style: AppTextStyles.sm14Regular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return _EarningsChart(earningsData: data);
          }),
        ],
      ),
    );
  }

  // ── Top Classes ───────────────────────────────────────────────────────────

  Widget _buildTopClasses() {
    return Obx(() {
      if (_ctrl.isLoadingTopClasses.value && _ctrl.topClasses.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.actionPrimary),
          ),
        );
      }
      if (_ctrl.topClasses.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: AppText(
              "No class data yet",
              style: AppTextStyles.sm14Regular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }
      return Column(
        children: _ctrl.topClasses
            .map((cls) => _TopClassItem(cls: cls))
            .toList(),
      );
    });
  }
}

// ─── Earnings Chart ────────────────────────────────────────────────────────────

class _EarningsChart extends StatelessWidget {
  const _EarningsChart({required this.earningsData});
  final TrainerEarningsModel earningsData;

  @override
  Widget build(BuildContext context) {
    final items = earningsData.data;
    final maxVal = earningsData.maxEarnings;

    // Y-axis: derive 5 evenly-spaced labels from 0 to maxVal
    final yLabels = List.generate(5, (i) {
      final v = maxVal * (4 - i) / 4;
      return v >= 1000
          ? '\$${(v / 1000).toStringAsFixed(0)}k'
          : '\$${v.toStringAsFixed(0)}';
    });

    return SizedBox(
      height: 200.h,
      child: Row(
        children: [
          // Y-axis labels
          Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: yLabels
                  .map(
                    (l) => AppText(
                      l,
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: const Color(0xFF828282),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(width: 8.w),
          // Chart area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (_) => _DashedGridLine()),
                      ),
                      // Bars
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: items.map((item) {
                            final factor = maxVal > 0
                                ? (item.earnings / maxVal).clamp(0.0, 1.0)
                                : 0.0;
                            final barW = items.length <= 7
                                ? 20.0
                                : items.length <= 14
                                ? 12.0
                                : 6.0;
                            return _EarningsBar(
                              heightFactor: factor,
                              width: barW,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: items.map((item) {
                    // For many items (monthly days), show every 5th
                    final showLabel =
                        items.length <= 12 ||
                        items.indexOf(item) == 0 ||
                        (items.indexOf(item) + 1) % 5 == 0 ||
                        items.indexOf(item) == items.length - 1;
                    return Expanded(
                      child: Center(
                        child: AppText(
                          showLabel ? item.label : '',
                          style: AppTextStyles.xs12Regular.copyWith(
                            color: const Color(0xFF828282),
                            fontSize: items.length > 12 ? 8.sp : 11.sp,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsBar extends StatelessWidget {
  final double heightFactor; // 0.0 – 1.0
  final double width;

  const _EarningsBar({required this.heightFactor, required this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: width.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        FractionallySizedBox(
          heightFactor: heightFactor.clamp(0.02, 1.0),
          child: Container(
            width: width.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top Class Item ────────────────────────────────────────────────────────────

class _TopClassItem extends StatelessWidget {
  const _TopClassItem({required this.cls});
  final TrainerTopClassModel cls;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  cls.name,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                AppText(
                  '${cls.displayClassType} · ${cls.displaySessionFormat}',
                  style: AppTextStyles.xs12Regular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${cls.bookingCount} bookings',
                style: AppTextStyles.xs12Regular.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              AppText(
                NumberFormat.currency(
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(cls.totalRevenue),
                style: AppTextStyles.xs12Regular.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9F9F9),
          boxShadow: [
            BoxShadow(
              color: AppColors.actionPrimary,
              blurRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 20, color: Colors.black)),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ProfileStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF2F2F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24.w, color: iconColor),
          const Spacer(),
          AppText(
            value,
            style: AppTextStyles.xl20SemiBold.copyWith(
              color: AppColors.textPrimary,
              fontSize: 22.sp,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            title,
            style: AppTextStyles.xs12Regular.copyWith(
              color: const Color(0xFF828282),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedGridLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1.h,
      child: CustomPaint(
        painter: _DashedLinePainter(color: Colors.grey.shade300),
      ),
    );
  }
}

// ─── Payout Banner ─────────────────────────────────────────────────────────────

class _PayoutBanner extends StatelessWidget {
  const _PayoutBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.statusWarningSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.statusWarning,
              size: 20,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppText(
                'Set up payouts to accept bookings',
                style: AppTextStyles.sm14Medium.copyWith(
                  color: AppColors.statusWarning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.statusWarning,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 3, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
