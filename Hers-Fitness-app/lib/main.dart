import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'Helpers/route.dart';
import 'controllers/trainer/trainer_profile_controller.dart';
import 'services/fcm_service.dart';
import 'utils/AppConstants/app_constant.dart';
import 'utils/AppTheme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.instance.initialize();
  if (AppConstants.Publishable_key.trim().isNotEmpty) {
    Stripe.publishableKey = AppConstants.Publishable_key.trim();
    await Stripe.instance.applySettings();
  }
  _initDeepLinks();
  runApp(const MyApp());
}

void _initDeepLinks() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    final path = uri.path;
    if (uri.scheme == 'herfitness' &&
        (path == '/trainer/payout/return' ||
            path == '/trainer/payout/refresh')) {
      if (Get.isRegistered<TrainerProfileController>()) {
        Get.find<TrainerProfileController>().fetchPayoutStatus();
      }
      if (Get.currentRoute != AppRoutes.trainerPayoutScreen) {
        Get.toNamed(AppRoutes.trainerPayoutScreen);
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          getPages: AppRoutes.page,
          initialRoute: AppRoutes.splashScreen,
        );
      },
    );
  }
}
