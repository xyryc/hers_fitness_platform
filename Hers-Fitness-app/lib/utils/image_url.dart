import 'package:fitness/utils/AppConstants/app_constant.dart';

String? normalizeImageUrl(dynamic value) {
  final rawText = value?.toString().trim();
  if (rawText == null || rawText.isEmpty || rawText.toLowerCase() == 'null') {
    return null;
  }

  final text = rawText.replaceAll(r'\', '/');
  if (text.startsWith('http://') ||
      text.startsWith('https://') ||
      text.startsWith('data:')) {
    return text;
  }

  if (text.startsWith('//')) {
    return 'https:$text';
  }

  final baseUrl = AppConstants.BASE_URL.trim();
  if (baseUrl.isEmpty) return text;

  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = text.startsWith('/') ? text : '/$text';

  return '$normalizedBase$normalizedPath';
}
