import 'package:fitness/views/Feature/common/_static_content_screen.dart';
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticContentScreen(
      contentKey: 'terms_of_service',
      fallbackTitle: 'Terms of Service',
    );
  }
}
