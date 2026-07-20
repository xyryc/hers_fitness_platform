import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/controllers/trainer/trainer_location_controller.dart';
import 'package:fitness/services/auth_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../Helpers/route.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.trainerBottomNavScreen);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                children: [
                  _buildSectionTitle("General"),
                  _buildSettingItem(
                    icon: Icons.person_outline_rounded,
                    title: "Personal Information",
                    onTap: () => Get.toNamed(AppRoutes.personalInfoScreen),
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_none_rounded,
                    title: "Notifications settings",
                    onTap: () =>
                        Get.toNamed(AppRoutes.notificationSettingsScreen),
                  ),
                  _buildSettingItem(
                    icon: Icons.credit_card_rounded,
                    title: "Transactions",
                    onTap: () =>
                        Get.toNamed(AppRoutes.trainerTransactionsScreen),
                  ),

                  SizedBox(height: 24.h),
                  _buildSectionTitle("Location"),
                  _buildLiveLocationSwitch(),
                  _buildBaseLocationItem(),

                  SizedBox(height: 24.h),
                  _buildSectionTitle("Security & Privacy"),
                  _buildSettingItem(
                    icon: Icons.lock_outline_rounded,
                    title: "Change Password",
                    onTap: () =>
                        Get.toNamed(AppRoutes.profileChangePasswordScreen),
                  ),
                  _buildSettingItem(
                    icon: Icons.description_outlined,
                    title: "Privacy Policy",
                    onTap: () => Get.toNamed(AppRoutes.privacyPolicyScreen),
                  ),
                  _buildSettingItem(
                    icon: Icons.gavel_outlined,
                    title: "Terms of Service",
                    onTap: () => Get.toNamed(AppRoutes.termsOfServiceScreen),
                  ),

                  SizedBox(height: 24.h),
                  _buildSectionTitle("Help & Support"),
                  _buildSettingItem(
                    icon: Icons.info_outline_rounded,
                    title: "About Us",
                    onTap: () => Get.toNamed(AppRoutes.aboutUsScreen),
                  ),
                  _buildSettingItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "Help Center",
                    onTap: () => Get.toNamed(AppRoutes.helpCenterScreen),
                  ),

                  SizedBox(height: 24.h),
                  _buildSectionTitle("Danger Zone"),
                  _buildDeleteAccountButton(context),

                  SizedBox(height: 24.h),
                  _buildSectionTitle("Log Out"),
                  _buildSettingItem(
                    icon: Icons.logout_rounded,
                    title: "Sign Out",
                    onTap: () => _showLogoutDialog(context),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Delete Confirmation Dialog --------------------
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  "assets/icons/deleteIcon.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.redAccent,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                "Delete Account",
                style: AppTextStyles.base16SemiBold.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 8.h),
              AppText(
                "Are you sure to delete this account?",
                textAlign: TextAlign.center,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: const Color(0xFF454F5B),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: AppText(
                        "Cancel",
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final ctrl =
                            Get.isRegistered<TrainerProfileController>()
                            ? Get.find<TrainerProfileController>()
                            : Get.put(TrainerProfileController());

                        Get.dialog(
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.actionPrimary,
                            ),
                          ),
                          barrierDismissible: false,
                        );

                        final success = await ctrl.deleteAccount();
                        if (Get.isDialogOpen == true) Get.back();

                        if (success) {
                          try {
                            await AuthService().logout();
                          } catch (_) {}
                          Get.offAllNamed(AppRoutes.signInScreen);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                      ),
                      child: AppText(
                        "Delete",
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- Logout Confirmation Dialog --------------------
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.actionPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.actionPrimary,
                  size: 32.w,
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                "Log Out",
                style: AppTextStyles.base16SemiBold.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 8.h),
              AppText(
                "Are you sure you want to log out of this account?",
                textAlign: TextAlign.center,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: const Color(0xFF454F5B),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: AppText(
                        "Cancel",
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        Get.dialog(
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.actionPrimary,
                            ),
                          ),
                          barrierDismissible: false,
                        );

                        try {
                          await AuthService().logout();
                        } catch (_) {
                          // AuthService clears local tokens even if the server logout fails.
                        } finally {
                          if (Get.isDialogOpen == true) {
                            Get.back();
                          }
                        }

                        Get.offAllNamed(AppRoutes.signInScreen);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                      ),
                      child: AppText(
                        "Log Out",
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            onTap: () => Get.offAllNamed(AppRoutes.trainerBottomNavScreen),
            behavior: HitTestBehavior.opaque,
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
                "Account Settings",
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: AppText(
        title,
        style: AppTextStyles.base16SemiBold.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFF1F1F1)),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          title: AppText(
            title,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLocationSwitch() {
    final TrainerLocationController locationController =
        Get.isRegistered<TrainerLocationController>()
        ? Get.find<TrainerLocationController>()
        : Get.put(TrainerLocationController());

    return Obx(() {
      final isUpdating = locationController.isUpdating.value;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 4.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFF1F1F1)),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
            title: AppText(
              "Live location",
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: AppText(
                locationController.isOnline.value
                    ? "Members can see your current trainer location"
                    : "Turn on to show your live trainer location",
                style: AppTextStyles.xs12Regular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            trailing: isUpdating
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.actionPrimary,
                    ),
                  )
                : Switch.adaptive(
                    value: locationController.isOnline.value,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.actionPrimary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD9DDE3),
                    onChanged: locationController.toggleOnlineStatus,
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildBaseLocationItem() {
    final TrainerLocationController locationController =
        Get.isRegistered<TrainerLocationController>()
        ? Get.find<TrainerLocationController>()
        : Get.put(TrainerLocationController());

    return Obx(() {
      final isUpdating = locationController.isUpdating.value;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: isUpdating
                ? null
                : () => locationController.setCurrentLocationAsBase(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 4.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFF1F1F1)),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
            title: AppText(
              "Base location",
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: AppText(
                "Update your fixed trainer base location",
                style: AppTextStyles.xs12Regular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            trailing: isUpdating
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.actionPrimary,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r)),
      child: Material(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _showDeleteDialog(context),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          title: AppText(
            "Delete Account",
            style: AppTextStyles.sm14Medium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
