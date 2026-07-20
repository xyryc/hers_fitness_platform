import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TrainerPayoutScreen extends StatefulWidget {
  const TrainerPayoutScreen({super.key});

  @override
  State<TrainerPayoutScreen> createState() => _TrainerPayoutScreenState();
}

class _TrainerPayoutScreenState extends State<TrainerPayoutScreen>
    with WidgetsBindingObserver {
  late final TrainerProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TrainerProfileController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-refresh when trainer returns from the external browser
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_ctrl.payoutReady) {
      _ctrl.fetchPayoutStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: AppText(
          'Payout Setup',
          style: AppTextStyles.base16SemiBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => _ctrl.isLoadingPayout.value
                ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.actionPrimary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _ctrl.fetchPayoutStatus(),
                    tooltip: 'Refresh status',
                  ),
          ),
        ],
      ),
      body: Obx(() {
        final ready = _ctrl.payoutReady;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(isReady: ready),
              SizedBox(height: 32.h),
              if (!ready) ...[
                _InfoSection(),
                SizedBox(height: 32.h),
                _SetupButton(ctrl: _ctrl),
                SizedBox(height: 16.h),
                _ReturnNote(),
              ] else ...[
                _ActiveSection(),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isReady});
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final bg = isReady
        ? AppColors.statusSuccessSubtle
        : AppColors.statusWarningSubtle;
    final icon = isReady ? Icons.check_circle_rounded : Icons.warning_rounded;
    final iconColor = isReady
        ? AppColors.statusSuccess
        : AppColors.statusWarning;
    final title = isReady ? 'Payouts active' : 'Payouts not set up';
    final subtitle = isReady
        ? 'You are ready to accept bookings and receive payments.'
        : 'Complete Stripe onboarding to start accepting bookings.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                AppText(
                  subtitle,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'How it works',
          style: AppTextStyles.base16SemiBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        _Step(number: '1', text: 'Tap "Set up payouts" below.'),
        SizedBox(height: 12.h),
        _Step(
          number: '2',
          text:
              'You\'ll be taken to Stripe\'s secure page to enter your bank details.',
        ),
        SizedBox(height: 12.h),
        _Step(
          number: '3',
          text:
              'Once complete, return to the app. Your payout status will update automatically.',
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: AppColors.actionPrimary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AppText(
            number,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: AppText(
              text,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupButton extends StatelessWidget {
  const _SetupButton({required this.ctrl});
  final TrainerProfileController ctrl;

  Future<void> _onTap() async {
    final result = await ctrl.generateOnboardingLink();
    if (result == null) return;

    final url = result.onboardingUrl;
    if (url == null || url.isEmpty) {
      Get.snackbar(
        'Setup unavailable',
        'Could not retrieve the onboarding link. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      Get.snackbar(
        'Cannot open browser',
        'Please check your device settings and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: ctrl.isGeneratingOnboardingLink.value ? null : _onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionPrimary,
            disabledBackgroundColor: AppColors.actionPrimaryDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: ctrl.isGeneratingOnboardingLink.value
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textInverse,
                  ),
                )
              : AppText(
                  'Set up payouts',
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReturnNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: AppText(
            'After finishing on Stripe\'s page, return here — the status will refresh automatically.',
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Your account is connected to Stripe. Payments from bookings will be deposited to your bank account.',
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
