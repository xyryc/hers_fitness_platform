import 'dart:io';

import 'package:fitness/controllers/member/member_profile_controller.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../Helpers/route.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String selectedPeriod = "Yearly";
  late final MemberProfileController _profileController;
  final RxDouble _scrollOffset = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<MemberProfileController>()
        ? Get.find<MemberProfileController>()
        : Get.put(MemberProfileController());
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(DateTime.now().year - 10),
              lastDate: DateTime(DateTime.now().year + 10),
              initialDate: DateTime.now(),
              selectedDate: DateTime(selectedYear),
              onChanged: (DateTime dateTime) {
                setState(() {
                  selectedYear = dateTime.year;
                });
                _profileController.fetchMonthlyActivity(
                  selectedYear,
                  showError: true,
                );
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Month"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthName = [
                  "January",
                  "February",
                  "March",
                  "April",
                  "May",
                  "June",
                  "July",
                  "August",
                  "September",
                  "October",
                  "November",
                  "December",
                ][index];
                return ListTile(
                  title: Text(monthName),
                  selected: selectedMonth == index + 1,
                  onTap: () {
                    final newMonth = index + 1;
                    setState(() {
                      selectedMonth = newMonth;
                    });
                    Navigator.pop(context);
                    _profileController.fetchDailyActivity(
                      month: newMonth,
                      year: selectedYear,
                      showError: true,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

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
              () => SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, _profileController.profileImageUrl),
                    if (_profileController.isLoading.value)
                      LinearProgressIndicator(color: AppColors.actionPrimary),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          SizedBox(height: 12.h),
                          AppText(
                            _profileController.displayName,
                            style: AppTextStyles.xl20SemiBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
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
                                _profileController.displayLocation,
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // ── Activity Diagram ──────────────────────────────────
                          _buildActivityDiagram(context),
                          SizedBox(height: 32.h),

                          // ── Stats Row ─────────────────────────────────────────
                          _buildStatsRow(),
                          SizedBox(height: 24.h),

                          // ── Refer a Friend ────────────────────────────────────
                          _buildReferFriendButton(),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildHeader(BuildContext context, String imageUrl) {
    return SizedBox(
      height: 250.h,
      child: Stack(
        children: [
          // Background Gradient (Standard)
          _buildTopGradient(context),
          // Cover Photo
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
                  image: _profileController.coverPhotoUrl.value.isEmpty
                      ? const NetworkImage(
                              "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=600&auto=format&fit=crop",
                            )
                            as ImageProvider
                      : _profileController.coverPhotoUrl.value.startsWith(
                          'http',
                        )
                      ? NetworkImage(_profileController.coverPhotoUrl.value)
                      : FileImage(File(_profileController.coverPhotoUrl.value)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Change Cover Photo Button (Repositioned to bottom right of cover area)
          Positioned(
            top: 140.h,
            right: 30.w,
            child: GestureDetector(
              onTap: () => _profileController.pickCoverPhoto(),
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
          // Top Buttons (Standard Appbar Style)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomAppbar(
                showBack: false,
                onTap: () => Get.offAllNamed(AppRoutes.memberBottomNavScreen),
                trailing: GestureDetector(
                  onTap: () =>
                      Get.toNamed(AppRoutes.memberAccountSettingsScreen),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Profile Image
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 250.h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFDADF).withValues(alpha: 0.9),
                const Color(0xFFFFECEE).withValues(alpha: 0.8),
                const Color(0xFFFFF7F5).withValues(alpha: 0.58),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.46, 0.78, 1],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDiagram(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "$selectedPeriod Activity",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (selectedPeriod == "Yearly")
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
              if (selectedPeriod == "Monthly")
                GestureDetector(
                  onTap: () => _showMonthPicker(context),
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
                          [
                            "Jan",
                            "Feb",
                            "Mar",
                            "Apr",
                            "May",
                            "Jun",
                            "Jul",
                            "Aug",
                            "Sep",
                            "Oct",
                            "Nov",
                            "Dec",
                          ][selectedMonth - 1],
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
          SizedBox(height: 16.h),
          if (_profileController.isLoadingActivity.value) ...[
            LinearProgressIndicator(
              color: AppColors.actionPrimary,
              minHeight: 2.h,
            ),
            SizedBox(height: 14.h),
          ],
          Row(
            children: ["Weekly", "Monthly", "Yearly"].map((period) {
              bool isSelected = selectedPeriod == period;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPeriod = period;
                  });
                  if (period == "Weekly") {
                    _profileController.fetchActivity(showError: true);
                  } else if (period == "Monthly") {
                    _profileController.fetchDailyActivity(
                      month: selectedMonth,
                      year: selectedYear,
                      showError: true,
                    );
                  } else if (period == "Yearly") {
                    _profileController.fetchMonthlyActivity(
                      selectedYear,
                      showError: true,
                    );
                  }
                },
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

          // ── High-Fidelity Activity Bar Chart ──────────────────────────
          SizedBox(
            height: 200.h,
            child: Row(
              children: [
                // Y-Axis Labels
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 24.h,
                  ), // Align with chart area
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["100", "90", "80", "70", "60"].map((label) {
                      return AppText(
                        label,
                        style: AppTextStyles.xs12Regular.copyWith(
                          color: const Color(0xFF828282),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 12.w),
                // Chart Area
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            // Grid Lines (Horizontal)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                (index) => _DashedGridLine(),
                              ),
                            ),
                            // Bars Area
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: _buildBars(),
                            ),
                          ],
                        ),
                      ),
                      // Labels Row
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: _buildLabels(),
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

  Widget _buildBars() {
    final bars = _activityBars();
    double barWidth;
    if (selectedPeriod == "Weekly") {
      barWidth = 20.0;
    } else if (selectedPeriod == "Monthly") {
      int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
      barWidth = (240 / daysInMonth) - 2;
      if (barWidth < 4) barWidth = 4;
    } else {
      barWidth = 14.0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((item) {
        return _Bar(day: item.label, value: item.value, width: barWidth);
      }).toList(),
    );
  }

  Widget _buildLabels() {
    final labels = _activityLabels();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) {
        return Expanded(
          child: Center(
            child: AppText(
              label,
              style: AppTextStyles.xs12Regular.copyWith(
                color: const Color(0xFF828282),
                fontSize: selectedPeriod == "Monthly" ? 10.sp : 12.sp,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_ActivityBarData> _activityBars() {
    if (selectedPeriod == "Weekly") {
      final days = _profileController.weeklyActivity.value?.days ?? const [];
      if (days.isEmpty) {
        return List.generate(7, (_) => const _ActivityBarData('', 0));
      }

      return days
          .map(
            (day) => _ActivityBarData(
              day.shortLabel,
              day.activityPercentage.toDouble(),
            ),
          )
          .toList();
    } else if (selectedPeriod == "Monthly") {
      final days = _profileController.dailyActivity.value?.days;
      if (days == null || days.isEmpty) {
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        return List.generate(
          daysInMonth,
          (index) => _ActivityBarData('${index + 1}', 0),
        );
      }
      return days
          .map(
            (day) => _ActivityBarData(
              '${day.day}',
              day.activityPercentage.toDouble(),
            ),
          )
          .toList();
    }

    final months = _profileController.monthlyActivity.value?.months ?? const [];
    if (months.isEmpty) {
      return List.generate(12, (_) => const _ActivityBarData('', 0));
    }

    return months
        .map(
          (month) => _ActivityBarData(
            month.shortLabel,
            month.activityPercentage.toDouble(),
          ),
        )
        .toList();
  }

  List<String> _activityLabels() {
    if (selectedPeriod == "Weekly") {
      final days = _profileController.weeklyActivity.value?.days ?? const [];
      if (days.isEmpty) return const ["M", "T", "W", "T", "F", "S", "S"];
      return days.map((day) => day.shortLabel).toList();
    } else if (selectedPeriod == "Monthly") {
      final apiDays = _profileController.dailyActivity.value?.days;
      final daysInMonth =
          apiDays?.length ?? DateTime(selectedYear, selectedMonth + 1, 0).day;
      return List.generate(daysInMonth, (index) {
        final day = index + 1;
        if (day == 1 || day % 5 == 0 || day == daysInMonth) return '$day';
        return '';
      });
    }

    final months = _profileController.monthlyActivity.value?.months ?? const [];
    if (months.isEmpty) {
      return const ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];
    }
    return months.map((month) => month.shortLabel).toList();
  }

  Widget _buildStatsRow() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            icon: Icons.calendar_month,
            iconColor: AppColors.actionPrimary,
            value: _profileController.ageValue,
            unit: _profileController.ageUnit,
            label: "Current Age",
          ),
          _buildStatCard(
            icon: Icons.monitor_weight,
            iconColor: const Color(0xFF16A34A),
            value: _profileController.weightValue,
            unit: _profileController.weightUnit,
            label: "Current weight",
          ),
          _buildStatCard(
            icon: Icons.restaurant_menu_rounded,
            iconColor: const Color(0xFF0284C7),
            value: _profileController.dietPreference,
            unit: "",
            label: "specific diet",
            isSmallValue: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
    bool isSmallValue = false,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24.sp),
            SizedBox(height: 16.h),
            isSmallValue
                ? AppText(
                    value,
                    style: AppTextStyles.base16Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AppText(
                            value,
                            style: AppTextStyles.xl20Bold.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 24.sp,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        SizedBox(width: 4.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: AppText(
                            unit,
                            style: AppTextStyles.sm14Medium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    ],
                  ),
            SizedBox(height: 8.h),
            AppText(
              label,
              style: AppTextStyles.xs12Regular.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferFriendButton() {
    return GestureDetector(
      onTap: () => _onReferFriendTapped(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.share_outlined,
                color: const Color(0xFF0284C7),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppText(
                "Refer a Friend",
                style: AppTextStyles.base16Medium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textPrimary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onReferFriendTapped(BuildContext context) async {
    // Show a loading indicator while fetching
    Get.dialog(
      Center(child: CircularProgressIndicator(color: AppColors.actionPrimary)),
      barrierDismissible: false,
    );

    final referral = await _profileController.getReferral();

    if (Get.isDialogOpen == true) Get.back();

    if (referral == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReferralBottomSheet(
        referralCode: referral.referralCode,
        referralLink: referral.referralLink,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String day;
  final double value; // Value between 0 and 100
  final double width;

  const _Bar({required this.day, required this.value, required this.width});

  @override
  Widget build(BuildContext context) {
    double heightFactor = value / 100;
    if (heightFactor < 0) heightFactor = 0;
    if (heightFactor > 1) heightFactor = 1;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Background Column (Full height of the grid area)
        Container(
          width: width.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        // Data Bar (Actual value)
        FractionallySizedBox(
          heightFactor: heightFactor,
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

class _ActivityBarData {
  final String label;
  final double value;

  const _ActivityBarData(this.label, this.value);
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

// ── Referral bottom sheet ─────────────────────────────────────────────────────

class _ReferralBottomSheet extends StatelessWidget {
  final String referralCode;
  final String referralLink;

  const _ReferralBottomSheet({
    required this.referralCode,
    required this.referralLink,
  });

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.actionPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderPrimary,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.actionPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.actionPrimary,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Refer a Friend',
                      style: AppTextStyles.base16SemiBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppText(
                      'Share your code and earn rewards',
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Referral code
            AppText(
              'Your Referral Code',
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _copy(context, referralCode, 'Referral code'),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      referralCode.isNotEmpty ? referralCode : '—',
                      style: AppTextStyles.xl20SemiBold.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 18.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        AppText(
                          'Copy',
                          style: AppTextStyles.sm14Medium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Share link button
            if (referralLink.isNotEmpty)
              GestureDetector(
                onTap: () => _copy(context, referralLink, 'Referral link'),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.actionPrimary,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        'Copy Invite Link',
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
