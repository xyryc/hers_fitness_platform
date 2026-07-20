import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/member/member_notification_controller.dart';
import 'package:fitness/controllers/my_classes_controller.dart';
import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Feature/Trainer/Classes/trainer_class_details_screen.dart';
import 'package:fitness/views/Feature/Trainer/Home/widgets/dashboard_stat_card.dart';
import 'package:fitness/views/Feature/Trainer/Home/widgets/next_class_card.dart';
import 'package:fitness/views/Feature/Trainer/Home/widgets/timeline_schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class TrainerHomeScreen extends StatelessWidget {
  const TrainerHomeScreen({super.key});

  void _showDetails(BuildContext context, Map<String, dynamic> classData) {
    Get.to(() => TrainerClassDetailsScreen(classData: classData));
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is available
    final MyClassesController classesController =
        Get.isRegistered<MyClassesController>()
        ? Get.find<MyClassesController>()
        : Get.put(MyClassesController());
    final TrainerProfileController profileController =
        Get.isRegistered<TrainerProfileController>()
        ? Get.find<TrainerProfileController>()
        : Get.put(TrainerProfileController());
    final MemberNotificationController notificationController =
        Get.isRegistered<MemberNotificationController>()
        ? Get.find<MemberNotificationController>()
        : Get.put(MemberNotificationController());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _buildTopGradient(context),
          Column(
            children: [
              _buildHeader(context, profileController, notificationController),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 24.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Dashboard Section ──────────────────────────
                      AppText(
                        "Dashboard",
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 10),

                      Obx(() {
                        final stats = classesController.dashboardStats.value;
                        String statVal(String key, {int decimals = 0}) {
                          final v = stats?[key];
                          if (v == null) return '—';
                          final d = double.tryParse(v.toString());
                          if (d == null) return v.toString();
                          return decimals > 0
                              ? d.toStringAsFixed(decimals)
                              : d.toStringAsFixed(0);
                        }

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8.h,
                          crossAxisSpacing: 8.w,
                          childAspectRatio: 1.25,
                          children: [
                            DashboardStatCard(
                              title: "Total Classes",
                              value: statVal('totalClasses'),
                              icon: Icons.calendar_month_rounded,
                              iconColor: const Color(0xFFF7869A),
                              onTap: () => Get.offAllNamed(
                                AppRoutes.trainerBottomNavScreen,
                                arguments: {'initialIndex': 1},
                              ),
                            ),
                            DashboardStatCard(
                              title: "Total Attendance",
                              value: statVal('totalAttendance'),
                              icon: Icons.people_alt_rounded,
                              iconColor: const Color(0xFF0284C7),
                              onTap: () => Get.offAllNamed(
                                AppRoutes.trainerBottomNavScreen,
                                arguments: {'initialIndex': 2},
                              ),
                            ),
                            DashboardStatCard(
                              title: "Avg Class Size",
                              value: statVal('avgClassSize', decimals: 1),
                              icon: Icons.trending_up_rounded,
                              iconColor: const Color(0xFF16A34A),
                              onTap: () => Get.offAllNamed(
                                AppRoutes.trainerBottomNavScreen,
                                arguments: {'initialIndex': 1},
                              ),
                            ),
                            DashboardStatCard(
                              title: "Overall Rating",
                              value: statVal('overallRating', decimals: 1),
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              onTap: () =>
                                  Get.toNamed(AppRoutes.trainerReviewsScreen),
                            ),
                          ],
                        );
                      }),
                      SizedBox(height: 10.h),

                      // ── Next Class Section ──────────────────────────
                      AppText(
                        "Next Class",
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      Obx(() {
                        if (classesController.isDashboardLoading.value &&
                            classesController.nextClass.value == null) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: CircularProgressIndicator(
                                color: AppColors.actionPrimary,
                              ),
                            ),
                          );
                        }

                        final next = classesController.nextClass.value;
                        if (next == null) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: AppText(
                                "No upcoming classes",
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return NextClassCard(
                          classData: next,
                          imageUrl: next['imageUrl']?.toString(),
                          onTap: () => _showDetails(context, next),
                        );
                      }),
                      SizedBox(height: 32.h),

                      // ── Today's Schedule Section ────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "Today's Schedule",
                            style: AppTextStyles.base16SemiBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.scheduleScreen);
                            },
                            child: AppText(
                              "View all",
                              style: AppTextStyles.sm14Medium.copyWith(
                                color: const Color(0xFFF7869A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      Obx(() {
                        final scheduleItems = classesController.todayClasses
                            .take(2)
                            .toList();

                        if (classesController.isDashboardLoading.value &&
                            scheduleItems.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: CircularProgressIndicator(
                                color: AppColors.actionPrimary,
                              ),
                            ),
                          );
                        }

                        if (scheduleItems.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Center(
                              child: AppText(
                                "No classes today",
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: List.generate(scheduleItems.length, (
                            index,
                          ) {
                            final item = scheduleItems[index];
                            return TimelineScheduleCard(
                              time: item["time"]?.toString() ?? "N/A",
                              title: item["title"]?.toString() ?? "Class",
                              date: item["date"]?.toString() ?? "",
                              icon: Icons.fitness_center_rounded,
                              isLast: index == scheduleItems.length - 1,
                            );
                          }),
                        );
                      }),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ],
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
      height: MediaQuery.of(context).padding.top + 250.h,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
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
            Positioned(
              left: -78.w,
              top: -38.h,
              width: 220.w,
              height: 220.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFBECB).withValues(alpha: 0.5),
                      const Color(0xFFFFDDE4).withValues(alpha: 0.26),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -76.w,
              top: -26.h,
              width: 230.w,
              height: 230.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFC1CF).withValues(alpha: 0.45),
                      const Color(0xFFFFE1E7).withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TrainerProfileController profileController,
    MemberNotificationController notificationController,
  ) {
    return Obx(() {
      final imageUrl = profileController.profileImageUrl;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20.w,
          MediaQuery.of(context).padding.top + 16.h,
          20.w,
          24.h,
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            // Profile Image
            GestureDetector(
              onTap: () {
                Get.toNamed(AppRoutes.trainerProfileScreen);
              },
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: imageUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: imageUrl.isEmpty
                    ? Icon(Icons.person, color: AppColors.textTertiary)
                    : null,
              ),
            ),
            SizedBox(width: 14.w),
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Welcome back",
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppText(
                    profileController.displayName,
                    style: AppTextStyles.base16SemiBold.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Notification Icon
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.notificationScreen),
              child: Obx(() {
                final unreadCount = notificationController.unreadCount.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
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
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/icons/notificationIcon.svg",
                          width: 24.w,
                          height: 24.w,
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: 18.w,
                            minHeight: 18.w,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          decoration: BoxDecoration(
                            color: AppColors.statusError,
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(color: Colors.white, width: 2.w),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: AppTextStyles.xxs9Bold.copyWith(
                                color: Colors.white,
                                fontSize: 8.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
