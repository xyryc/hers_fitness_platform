import 'package:flutter/material.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/services/fcm_service.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final accessToken = await _tokenStorage.getAccessToken();
    final role = (await _tokenStorage.getUserRole())?.toLowerCase();
    if (!mounted) return;

    if (accessToken == null || accessToken.isEmpty) {
      Get.offAllNamed(AppRoutes.welcomeScreen);
      return;
    }

    // Register FCM token on app restore
    await FcmService.instance.registerCurrentToken();

    if (role == 'trainer') {
      Get.offAllNamed(AppRoutes.trainerBottomNavScreen);
      return;
    }

    Get.offAllNamed(AppRoutes.memberBottomNavScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.actionPrimaryHover,
              Colors.white,
              AppColors.actionPrimaryHover,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/splashImg.png',
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
