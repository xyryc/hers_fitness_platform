import 'package:fitness/views/Feature/common/_static_content_screen.dart';
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      contentKey: 'about_us',
      fallbackTitle: 'About Us',
    );
  }
}
