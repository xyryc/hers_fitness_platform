import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/common/chat_controller.dart';
import 'package:fitness/controllers/member/member_notification_controller.dart';
import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/services/notification_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:fitness/views/Feature/common/chat/chat_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final TokenStorage _tokenStorage = TokenStorage();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) => registerToken(token: token),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleNavigation(initialMessage);
    }

    unawaited(registerCurrentToken());
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> registerCurrentToken() async {
    final token = await _messaging.getToken();
    await registerToken(token: token);
  }

  Future<void> registerToken({String? token}) async {
    if (token == null || token.trim().isEmpty) return;

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    final role = (await _tokenStorage.getUserRole())?.toLowerCase();
    if (role != 'member' && role != 'trainer') return;

    final deviceId = await _tokenStorage.getClientId();

    await _notificationService.registerDeviceToken(
      token: token,
      platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      deviceId: deviceId,
    );
  }

  Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _notificationService.unregisterDeviceToken(token: token);
      }
    } catch (_) {
      // Ignore token deletion errors on logout
    }
  }

  Future<void> navigateFromNotificationData({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final normalizedType = type.toUpperCase();
    final role = (await _tokenStorage.getUserRole())?.toLowerCase();
    final isTrainer = role == 'trainer';

    switch (normalizedType) {
      case 'CHAT_MESSAGE':
        await _openConversation(data);
        return;
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_RESCHEDULED':
      case 'BOOKING_COMPLETED':
        _openBookingsArea(isTrainer, data);
        return;
      case 'BOOKING_RESCHEDULE_REQUESTED':
        _openBookingsArea(isTrainer, data);
        return;
      case 'TRAINER_REVIEW_RECEIVED':
        if (isTrainer) {
          Get.toNamed(AppRoutes.trainerReviewsScreen, arguments: data);
        } else {
          Get.toNamed(AppRoutes.notificationScreen);
        }
        return;
      case 'TEST_PUSH':
        Get.toNamed(AppRoutes.notificationScreen);
        return;
      case 'CLASS_CANCELLED':
        _openBookingsArea(isTrainer, data);
        return;
      case 'BOOKING_PAYMENT_FAILED':
        _openBookingsArea(isTrainer, data);
        return;
      case 'ACCOUNT_VERIFICATION_APPROVED':
      case 'ACCOUNT_VERIFICATION_REJECTED':
        Get.toNamed(AppRoutes.memberProfileScreen, arguments: data);
        return;
      default:
        Get.toNamed(AppRoutes.notificationScreen);
    }
  }

  Future<void> _openConversation(Map<String, dynamic> data) async {
    final conversationId = _readString(data, const [
      'conversationId',
      'conversation_id',
    ]);

    if (conversationId == null || conversationId.isEmpty) {
      await _openChatTab();
      return;
    }

    final controller = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    await controller.fetchConversations();
    final contact = controller.contacts.firstWhereOrNull(
      (item) => item.id == conversationId,
    );

    if (contact == null) {
      await _openChatTab();
      return;
    }

    Get.to(() => ChatScreen(contact: contact));
  }

  Future<void> _openChatTab() async {
    final role = (await _tokenStorage.getUserRole())?.toLowerCase();
    Get.offAllNamed(
      role == 'trainer'
          ? AppRoutes.trainerBottomNavScreen
          : AppRoutes.memberBottomNavScreen,
      arguments: {'initialIndex': 3},
    );
  }

  void _openBookingsArea(bool isTrainer, Map<String, dynamic> data) {
    if (isTrainer) {
      Get.toNamed(
        AppRoutes.trainerBottomNavScreen,
        arguments: {'initialIndex': 1},
      );
      return;
    }

    Get.toNamed(AppRoutes.myClassesScreen, arguments: data);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _refreshUnreadCount();

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    showPushNotification(
      title ?? 'Notification',
      body ?? '',
      onTap: () => _handleOpenedMessage(message),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _refreshUnreadCount();
    final data = _normalizedData(message.data);
    final type = _notificationType(data);
    if (type == null || type.isEmpty) {
      Get.toNamed(AppRoutes.notificationScreen);
      return;
    }

    unawaited(navigateFromNotificationData(type: type, data: data));
  }

  void _scheduleNavigation(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        () => _handleOpenedMessage(message),
      );
    });
  }

  void _refreshUnreadCount() {
    if (Get.isRegistered<MemberNotificationController>()) {
      unawaited(Get.find<MemberNotificationController>().fetchUnreadCount());
    }
  }

  Map<String, dynamic> _normalizedData(Map<String, dynamic> data) {
    final normalized = data.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final nested = normalized['data'];
    if (nested is Map) {
      normalized.addAll(
        nested.map((key, value) => MapEntry(key.toString(), value)),
      );
    } else if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) {
          normalized.addAll(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {
        // Keep the original flat payload if the nested data is not JSON.
      }
    }
    return normalized;
  }

  String? _notificationType(Map<String, dynamic> data) {
    return _readString(data, const ['type', 'notificationType']);
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
