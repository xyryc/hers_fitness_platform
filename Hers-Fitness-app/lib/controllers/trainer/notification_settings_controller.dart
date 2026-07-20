import 'dart:async';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/notification_preferences_model.dart';
import 'package:fitness/services/notification_preferences_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:get/get.dart';

class NotificationSettingsController extends GetxController {
  NotificationSettingsController({NotificationPreferencesService? service})
    : _service = service ?? NotificationPreferencesService();

  final NotificationPreferencesService _service;

  final prefs = Rxn<NotificationPreferencesModel>();
  final isLoading = false.obs;
  final isSaving = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchPreferences();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> fetchPreferences() async {
    try {
      isLoading.value = true;
      prefs.value = await _service.getPreferences();
    } on ApiException catch (e) {
      // If the endpoint doesn't exist yet, fall back to safe defaults.
      if (e.statusCode == 404) {
        prefs.value = const NotificationPreferencesModel();
      } else {
        showAppSnackbar(
          'Could not load preferences',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      // Fall back to safe defaults so the UI is still usable.
      prefs.value = const NotificationPreferencesModel();
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by each toggle. Updates local state immediately for responsiveness,
  /// then debounces the PATCH call by 500 ms.
  void toggle(String field, bool value) {
    final current = prefs.value;
    if (current == null) return;

    // Optimistic local update
    prefs.value = _applyField(current, field, value);

    // Debounced API call
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _patch(field, value);
    });
  }

  Future<void> _patch(String field, bool value) async {
    try {
      isSaving.value = true;
      final updated = await _service.updatePreferences({field: value});
      prefs.value = updated;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Could not save preference',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Revert optimistic update by re-fetching
      await fetchPreferences();
    } catch (_) {
      await fetchPreferences();
    } finally {
      isSaving.value = false;
    }
  }

  static NotificationPreferencesModel _applyField(
    NotificationPreferencesModel current,
    String field,
    bool value,
  ) {
    switch (field) {
      // ── Trainer fields ──────────────────────────────────────────────────
      case 'newBooking':
        return current.copyWith(newBooking: value);
      case 'classCheckIn':
        return current.copyWith(classCheckIn: value);
      case 'paymentReceived':
        return current.copyWith(paymentReceived: value);
      // ── Member fields ───────────────────────────────────────────────────
      case 'bookingConfirmation':
        return current.copyWith(bookingConfirmation: value);
      case 'bookingCancellation':
        return current.copyWith(bookingCancellation: value);
      case 'paymentConfirmation':
        return current.copyWith(paymentConfirmation: value);
      case 'trainerMessage':
        return current.copyWith(trainerMessage: value);
      // ── Shared fields ───────────────────────────────────────────────────
      case 'classReminder':
        return current.copyWith(classReminder: value);
      case 'systemAnnouncements':
        return current.copyWith(systemAnnouncements: value);
      case 'emailNotifications':
        return current.copyWith(emailNotifications: value);
      case 'pushNotifications':
        return current.copyWith(pushNotifications: value);
      default:
        return current;
    }
  }
}
