import 'package:fitness/views/Feature/common/_static_content_screen.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      contentKey: 'privacy_policy',
      fallbackTitle: 'Privacy Policy',
    );
  }
}
