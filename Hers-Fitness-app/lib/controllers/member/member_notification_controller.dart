import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/app_notification_model.dart';
import 'package:fitness/services/fcm_service.dart';
import 'package:fitness/services/notification_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MemberNotificationController extends GetxController {
  MemberNotificationController({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  final notifications = <AppNotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final isMarkingAllRead = false.obs;
  final isDeletingAll = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnreadCount();
  }

  Future<void> fetchNotifications({bool showError = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _notificationService.getNotifications();
      notifications.assignAll(response);
      await fetchUnreadCount();
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (showError) _showError(error.message);
    } catch (_) {
      errorMessage.value = 'Could not load notifications.';
      if (showError) _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _notificationService.getUnreadCount();
      unreadCount.value = response.unreadCount;
    } on ApiException catch (e) {
      unreadCount.value = 0;
      debugPrint('Unread count API error: ${e.message}');
    } catch (e) {
      unreadCount.value = 0;
      debugPrint('Unread count error: $e');
    }
  }

  Future<void> openNotification(AppNotificationModel notification) async {
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }

    await FcmService.instance.navigateFromNotificationData(
      type: notification.type,
      data: notification.data,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    try {
      await _notificationService.markAsRead(notificationId);
      final index = notifications.indexWhere(
        (item) => item.id == notificationId,
      );
      if (index != -1 && !notifications[index].isRead) {
        notifications[index] = notifications[index].copyWith(
          readAt: DateTime.now(),
        );
      }
      if (unreadCount.value > 0) unreadCount.value--;
    } catch (_) {
      await fetchUnreadCount();
    }
  }

  Future<void> markAllAsRead() async {
    if (isMarkingAllRead.value) return;

    try {
      isMarkingAllRead.value = true;
      await _notificationService.markAllAsRead();
      final now = DateTime.now();
      notifications.assignAll(
        notifications.map(
          (item) => item.isRead ? item : item.copyWith(readAt: now),
        ),
      );
      unreadCount.value = 0;
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not mark notifications as read.');
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    final existing = notifications.firstWhereOrNull(
      (item) => item.id == notificationId,
    );

    try {
      await _notificationService.deleteNotification(notificationId);
      notifications.removeWhere((item) => item.id == notificationId);
      if (existing != null && !existing.isRead && unreadCount.value > 0) {
        unreadCount.value--;
      }
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not delete this notification.');
    }
  }

  Future<void> deleteAllNotifications() async {
    if (isDeletingAll.value) return;

    try {
      isDeletingAll.value = true;
      await _notificationService.deleteAllNotifications();
      notifications.clear();
      unreadCount.value = 0;
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not clear notifications.');
    } finally {
      isDeletingAll.value = false;
    }
  }

  void _showError(String message) {
    showAppSnackbar(
      'Notifications failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
