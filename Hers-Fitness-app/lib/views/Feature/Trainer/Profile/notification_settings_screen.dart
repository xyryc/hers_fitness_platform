import 'package:fitness/controllers/trainer/notification_settings_controller.dart';
import 'package:fitness/models/notification_preferences_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<NotificationSettingsController>()
        ? Get.find<NotificationSettingsController>()
        : Get.put(NotificationSettingsController());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                );
              }
              final p = ctrl.prefs.value;
              if (p == null) return const SizedBox.shrink();

              // Branch on role; default to MEMBER if unknown
              return p.role == 'TRAINER'
                  ? _buildTrainerList(p, ctrl)
                  : _buildMemberList(p, ctrl);
            }),
          ),
        ],
      ),
    );
  }

  // ── Member toggle list ──────────────────────────────────────────────────────

  Widget _buildMemberList(
    NotificationPreferencesModel p,
    NotificationSettingsController ctrl,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        _buildSectionTitle('Bookings & Classes'),
        _buildSwitchItem(
          icon: Icons.event_available_outlined,
          title: 'Booking Confirmation',
          subtitle: 'When you successfully book a class',
          value: p.bookingConfirmation,
          field: 'bookingConfirmation',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.event_busy_outlined,
          title: 'Booking Cancellation',
          subtitle: 'When a booking is cancelled by you or the trainer',
          value: p.bookingCancellation,
          field: 'bookingCancellation',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.calendar_today_outlined,
          title: 'Class Reminder',
          subtitle: 'Reminder before your upcoming class starts',
          value: p.classReminder,
          field: 'classReminder',
          ctrl: ctrl,
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle('Payments'),
        _buildSwitchItem(
          icon: Icons.monetization_on_outlined,
          title: 'Payment Confirmation',
          subtitle: 'When a payment is processed for your booking',
          value: p.paymentConfirmation,
          field: 'paymentConfirmation',
          ctrl: ctrl,
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle('Messages'),
        _buildSwitchItem(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Trainer Message',
          subtitle: 'When your trainer sends you a message',
          value: p.trainerMessage,
          field: 'trainerMessage',
          ctrl: ctrl,
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle('General'),
        _buildSwitchItem(
          icon: Icons.notifications_none_rounded,
          title: 'Push Notifications',
          subtitle: 'Receive push notifications on this device',
          value: p.pushNotifications,
          field: 'pushNotifications',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          subtitle: 'Receive summaries and updates by email',
          value: p.emailNotifications,
          field: 'emailNotifications',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.campaign_outlined,
          title: 'System Announcements',
          subtitle: 'News and feature updates from Hers Fitness',
          value: p.systemAnnouncements,
          field: 'systemAnnouncements',
          ctrl: ctrl,
        ),
      ],
    );
  }

  // ── Trainer toggle list ─────────────────────────────────────────────────────

  Widget _buildTrainerList(
    NotificationPreferencesModel p,
    NotificationSettingsController ctrl,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        _buildSectionTitle('Bookings & Classes'),
        _buildSwitchItem(
          icon: Icons.event_available_outlined,
          title: 'New Booking',
          subtitle: 'When a member books one of your classes',
          value: p.newBooking,
          field: 'newBooking',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.calendar_today_outlined,
          title: 'Class Reminder',
          subtitle: 'Reminder before your upcoming class starts',
          value: p.classReminder,
          field: 'classReminder',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.how_to_reg_outlined,
          title: 'Class Check-In',
          subtitle: 'When a member checks into your class',
          value: p.classCheckIn,
          field: 'classCheckIn',
          ctrl: ctrl,
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle('Payments'),
        _buildSwitchItem(
          icon: Icons.monetization_on_outlined,
          title: 'Payment Received',
          subtitle: 'When you receive a booking payment',
          value: p.paymentReceived,
          field: 'paymentReceived',
          ctrl: ctrl,
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle('General'),
        _buildSwitchItem(
          icon: Icons.notifications_none_rounded,
          title: 'Push Notifications',
          subtitle: 'Receive push notifications on this device',
          value: p.pushNotifications,
          field: 'pushNotifications',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          subtitle: 'Receive summaries and updates by email',
          value: p.emailNotifications,
          field: 'emailNotifications',
          ctrl: ctrl,
        ),
        _buildSwitchItem(
          icon: Icons.campaign_outlined,
          title: 'System Announcements',
          subtitle: 'News and feature updates from Hers Fitness',
          value: p.systemAnnouncements,
          field: 'systemAnnouncements',
          ctrl: ctrl,
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
                'Notifications Settings',
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

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

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required String field,
    required NotificationSettingsController ctrl,
  }) {
    final switchController = ValueNotifier<bool>(value);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFF1F1F1)),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                AppText(
                  subtitle,
                  style: AppTextStyles.xs12Regular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AdvancedSwitch(
            controller: switchController,
            activeColor: AppColors.actionPrimary,
            inactiveColor: const Color(0xFF94A3B8),
            width: 44.w,
            height: 24.h,
            onChanged: (v) => ctrl.toggle(field, v),
          ),
        ],
      ),
    );
  }
}
