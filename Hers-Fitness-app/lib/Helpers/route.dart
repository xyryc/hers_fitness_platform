import 'package:get/get.dart';
import '../controllers/auth/sign_in_controller.dart';
import '../controllers/auth/trainer_register_controller.dart';
import '../views/Feature/Auth/sign_in_screen.dart';
import '../views/Feature/Member/BottomNav/member_bottom_nav_screen.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_one.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_three.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_two.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_four.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_five.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_six.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_seven.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_eight.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_nine.dart';
import '../views/Feature/Member/MemberOnboardingScreen/assessment_number_ten.dart';
import '../views/Feature/Member/MyClasses/my_classes_screen.dart';
import '../views/Feature/Member/Profile/member_account_setting_screen.dart';
import '../views/Feature/Member/Profile/member_personal_info_screen.dart';
import '../views/Feature/Member/Profile/member_profile_screen.dart';
import '../views/Feature/Member/Profile/member_transactions_screen.dart';
import '../views/Feature/Member/Trainer/trainer_list_screen.dart';
import '../views/Feature/Member/Trainer/trainer_details_screen.dart';
import '../views/Feature/Member/Trainer/trainer_reviews_screen.dart';
import '../views/Feature/Member/Trainer/book_trainer_screen.dart';
import '../views/Feature/SplashScreen/splash_screen.dart';
import '../views/Feature/Auth/Welcome/welcome_screen.dart';
import '../views/Feature/Auth/role_selection_screen.dart';
import '../views/Feature/Auth/member_sign_up_screen.dart';
import '../views/Feature/Auth/trainer_sign_up_screen.dart';
import '../views/Feature/Auth/forgot_password_screen.dart';
import '../views/Feature/Auth/reset_password_email_screen.dart';
import '../views/Feature/Auth/otp_verification_screen.dart';
import '../views/Feature/Auth/password_verification_screen.dart';
import '../views/Feature/Auth/change_password_screen.dart';
import '../views/Feature/Trainer/BottomNav/trainer_bottom_nav_screen.dart';
import '../views/Feature/Trainer/Profile/account_settings_screen.dart';
import '../views/Feature/Trainer/Profile/notification_settings_screen.dart';
import '../views/Feature/Trainer/Profile/personal_info_screen.dart';
import '../views/Feature/Trainer/Profile/trainer_profile_screen.dart';
import '../views/Feature/Trainer/Profile/trainer_transactions_screen.dart';
import '../views/Feature/Trainer/Profile/change_password_screen.dart'
    as profile;
import '../views/Feature/Trainer/Schedule/schedule_screen.dart';
import '../views/Feature/common/notification_screen.dart';
import '../views/Feature/common/privacy_policy_screen.dart';
import '../views/Feature/common/terms_of_service_screen.dart';
import '../views/Feature/common/about_us_screen.dart';
import '../views/Feature/common/help_center_screen.dart';
import '../views/Feature/common/identity_verification/identity_verification_screen.dart';
import '../views/Feature/Trainer/Payout/trainer_payout_screen.dart';

class AppRoutes {
  static String splashScreen = "/splash_screen";
  static String welcomeScreen = "/welcome_screen";
  static String roleSelectionScreen = "/role_selection_screen";
  static String signInScreen = "/sign_in_screen";
  static String memberSignUpScreen = "/member_sign_up_screen";
  static String trainerSignUpScreen = "/trainer_sign_up_screen";
  static String forgotPasswordScreen = "/forgot_password_screen";
  static String resetPasswordEmailScreen = "/reset_password_email_screen";
  static String otpVerificationScreen = "/otp_verification_screen";
  static String passwordVerificationScreen = "/password_verification_screen";
  static String changePasswordScreen = "/change_password_screen";
  static String scheduleScreen = "/schedule_screen";
  static String notificationScreen = "/notification_screen";
  static String trainerProfileScreen = "/trainer_profile_screen";
  static String accountSettingsScreen = "/account_settings_screen";
  static String personalInfoScreen = "/personal_info_screen";
  static String notificationSettingsScreen = "/notification_settings_screen";
  static String profileChangePasswordScreen = "/profile_change_password_screen";
  static String privacyPolicyScreen = "/privacy_policy_screen";
  static String termsOfServiceScreen = "/terms_of_service_screen";
  static String aboutUsScreen = "/about_us_screen";
  static String helpCenterScreen = "/help_center_screen";
  static String trainerBottomNavScreen = "/trainer_bottom_nav_screen";
  static String assessmentNumberOneScreen = "/assessment_number_one";
  static String assessmentNumberTwoScreen = "/assessment_number_two";
  static String assessmentNumberThreeScreen = "/assessment_number_three";
  static String assessmentNumberFourScreen = "/assessment_number_four";
  static String assessmentNumberFiveScreen = "/assessment_number_five";
  static String assessmentNumberSixScreen = "/assessment_number_six";
  static String assessmentNumberSevenScreen = "/assessment_number_seven";
  static String assessmentNumberEightScreen = "/assessment_number_eight";
  static String assessmentNumberNineScreen = "/assessment_number_nine";
  static String assessmentNumberTenScreen = "/assessment_number_ten";
  static String myClassesScreen = "/my_classes_screen";
  static String memberBottomNavScreen = "/member_bottom_nav_screen";
  static String trainerListScreen = "/trainer_list_screen";
  static String trainerDetailsScreen = "/trainer_details_screen";
  static String trainerReviewsScreen = "/trainer_reviews_screen";
  static String bookTrainerScreen = "/book_trainer_screen";
  static String memberProfileScreen = "/member_profile_screen";
  static String memberAccountSettingsScreen = "/member_account_setting_screen";
  static String memberPersonalInfoScreen = "/member_personal_info_screen";
  static String memberTransactionsScreen = "/member_transactions_screen";
  static String trainerTransactionsScreen = "/trainer_transactions_screen";
  static String trainerPayoutScreen = "/trainer_payout_screen";
  static String verifyIdentityScreen = "/verify_identity_screen";
  static String identityDocumentTypeScreen = "/identity_document_type_screen";
  static String identityCameraScreen = "/identity_camera_screen";
  static String identityCheckQualityScreen = "/identity_check_quality_screen";
  static String identityReviewScreen = "/identity_review_screen";

  static final List<GetPage> page = [
    GetPage(name: splashScreen, page: () => const SplashScreen()),
    GetPage(name: welcomeScreen, page: () => const WelcomeScreen()),
    GetPage(name: roleSelectionScreen, page: () => const RoleSelectionScreen()),
    GetPage(
      name: signInScreen,
      page: () => const SignInScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SignInController());
      }),
    ),
    GetPage(name: memberSignUpScreen, page: () => const MemberSignUpScreen()),
    GetPage(
      name: trainerSignUpScreen,
      page: () => const TrainerSignUpScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TrainerRegisterController());
      }),
    ),
    GetPage(
      name: forgotPasswordScreen,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: resetPasswordEmailScreen,
      page: () => const ResetPasswordEmailScreen(),
    ),
    GetPage(
      name: otpVerificationScreen,
      page: () => const OtpVerificationScreen(),
    ),
    GetPage(
      name: passwordVerificationScreen,
      page: () => const PasswordVerificationScreen(),
    ),
    GetPage(
      name: changePasswordScreen,
      page: () => const ChangePasswordScreen(),
    ),
    GetPage(name: scheduleScreen, page: () => const ScheduleScreen()),
    GetPage(name: notificationScreen, page: () => const NotificationScreen()),
    GetPage(
      name: trainerProfileScreen,
      page: () => const TrainerProfileScreen(),
    ),
    GetPage(
      name: accountSettingsScreen,
      page: () => const AccountSettingsScreen(),
    ),
    GetPage(name: personalInfoScreen, page: () => const PersonalInfoScreen()),
    GetPage(
      name: notificationSettingsScreen,
      page: () => const NotificationSettingsScreen(),
    ),
    GetPage(
      name: profileChangePasswordScreen,
      page: () => const profile.ChangePasswordScreen(),
    ),
    GetPage(name: privacyPolicyScreen, page: () => const PrivacyPolicyScreen()),
    GetPage(
      name: termsOfServiceScreen,
      page: () => const TermsOfServiceScreen(),
    ),
    GetPage(name: aboutUsScreen, page: () => const AboutUsScreen()),
    GetPage(name: helpCenterScreen, page: () => const HelpCenterScreen()),
    GetPage(
      name: trainerBottomNavScreen,
      page: () {
        final args = Get.arguments;
        final initialIndex = args is Map
            ? int.tryParse(args['initialIndex']?.toString() ?? '') ?? 0
            : 0;
        return TrainerBottomNavScreen(initialIndex: initialIndex);
      },
    ),
    GetPage(
      name: assessmentNumberOneScreen,
      page: () => AssessmentNumberOneScreen(),
    ),
    GetPage(
      name: assessmentNumberTwoScreen,
      page: () => AssessmentNumberTwoScreen(),
    ),
    GetPage(
      name: assessmentNumberThreeScreen,
      page: () => AssessmentNumberThreeScreen(),
    ),
    GetPage(
      name: assessmentNumberFourScreen,
      page: () => AssessmentNumberFourScreen(),
    ),
    GetPage(
      name: assessmentNumberFiveScreen,
      page: () => AssessmentNumberFiveScreen(),
    ),
    GetPage(
      name: assessmentNumberSixScreen,
      page: () => AssessmentNumberSixScreen(),
    ),
    GetPage(
      name: assessmentNumberSevenScreen,
      page: () => AssessmentNumberSevenScreen(),
    ),
    GetPage(
      name: assessmentNumberEightScreen,
      page: () => AssessmentNumberEightScreen(),
    ),
    GetPage(
      name: assessmentNumberNineScreen,
      page: () => AssessmentNumberNineScreen(),
    ),
    GetPage(
      name: assessmentNumberTenScreen,
      page: () => AssessmentNumberTenScreen(),
    ),
    GetPage(name: myClassesScreen, page: () => MemberMyClassesScreen()),
    GetPage(
      name: memberBottomNavScreen,
      page: () {
        final args = Get.arguments;
        final initialIndex = args is Map
            ? int.tryParse(args['initialIndex']?.toString() ?? '') ?? 0
            : 0;
        return MemberBottomNavScreen(initialIndex: initialIndex);
      },
    ),
    GetPage(name: trainerListScreen, page: () => TrainerListScreen()),
    GetPage(name: trainerDetailsScreen, page: () => TrainerDetailsScreen()),
    GetPage(
      name: trainerReviewsScreen,
      page: () => const TrainerReviewsScreen(),
    ),
    GetPage(name: bookTrainerScreen, page: () => const BookTrainerScreen()),
    GetPage(name: memberProfileScreen, page: () => const MemberProfileScreen()),
    GetPage(
      name: memberAccountSettingsScreen,
      page: () => MemberAccountSettingsScreen(),
    ),
    GetPage(
      name: memberPersonalInfoScreen,
      page: () => MemberPersonalInfoScreen(),
    ),
    GetPage(
      name: memberTransactionsScreen,
      page: () => const MemberTransactionsScreen(),
    ),
    GetPage(
      name: trainerTransactionsScreen,
      page: () => const TrainerTransactionsScreen(),
    ),
    GetPage(name: trainerPayoutScreen, page: () => const TrainerPayoutScreen()),
    GetPage(
      name: verifyIdentityScreen,
      page: () => const VerifyIdentityScreen(),
    ),
    GetPage(
      name: identityDocumentTypeScreen,
      page: () => const IdentityDocumentTypeScreen(),
    ),
    GetPage(
      name: identityCameraScreen,
      page: () => const IdentityCameraScreen(),
    ),
    GetPage(
      name: identityCheckQualityScreen,
      page: () => const IdentityCheckQualityScreen(),
    ),
    GetPage(
      name: identityReviewScreen,
      page: () => const IdentityReviewScreen(),
    ),
  ];
}
