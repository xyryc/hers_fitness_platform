import 'dart:async';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/trainer_schedule_model.dart';
import 'package:fitness/services/trainer_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TrainerScheduleController extends GetxController {
  TrainerScheduleController({TrainerScheduleService? service})
    : _service = service ?? TrainerScheduleService();

  final TrainerScheduleService _service;

  final RxList<TrainerScheduleDay> scheduleDays = <TrainerScheduleDay>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  Timer? _pollingTimer;

  static const _errorMessages = {
    'BOOKING_NOT_STARTED': "Session hasn't started yet",
    'BOOKING_NOT_ENDED': "Session hasn't ended yet",
    'TRAINER_CHECK_IN_NOT_ELIGIBLE': 'Member must check in first',
    'TRAINER_NOT_ELIGIBLE': 'Member must mark complete first',
    'BOOKING_ALREADY_COMPLETED': 'Session already completed',
    'BOOKING_NOT_FOUND': 'Booking not found',
    'RESCHEDULE_NOT_REQUESTED': 'No pending reschedule request',
  };

  @override
  void onInit() {
    super.onInit();
    fetchSchedule();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchSchedule(silent: true);
    });
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchSchedule({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final response = await _service.getSchedule(date: dateStr);
      scheduleDays.value = response.days;
    } on ApiException catch (e) {
      if (!silent) _showError(e.message);
    } catch (_) {
      if (!silent) _showError('Could not load schedule');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchSchedule();
  }

  TrainerScheduleDay? get currentDay {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    try {
      return scheduleDays.firstWhere((d) => d.date == dateStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> performCheckIn(String bookingId) async {
    isActionLoading.value = true;
    try {
      await _service.checkIn(bookingId);
      await fetchSchedule(silent: true);
      _showSuccess('Checked in successfully');
    } on ApiException catch (e) {
      _showError(_friendly(e.message));
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> performMarkComplete(String bookingId) async {
    isActionLoading.value = true;
    try {
      await _service.markComplete(bookingId);
      await fetchSchedule(silent: true);
      _showSuccess('Session marked as complete');
    } on ApiException catch (e) {
      _showError(_friendly(e.message));
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> performRequestReschedule(
    String bookingId, {
    required String scheduledDate,
    required String startTime,
  }) async {
    isActionLoading.value = true;
    try {
      await _service.requestReschedule(
        bookingId,
        scheduledDate: scheduledDate,
        startTime: startTime,
      );
      await fetchSchedule(silent: true);
      _showSuccess('Reschedule request sent');
    } on ApiException catch (e) {
      _showError(_friendly(e.message));
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> performAcceptReschedule(String bookingId) async {
    isActionLoading.value = true;
    try {
      await _service.acceptReschedule(bookingId);
      await fetchSchedule(silent: true);
      _showSuccess('Reschedule accepted');
    } on ApiException catch (e) {
      _showError(_friendly(e.message));
    } finally {
      isActionLoading.value = false;
    }
  }

  String _friendly(String code) => _errorMessages[code] ?? code;

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 3),
    );
  }
}
