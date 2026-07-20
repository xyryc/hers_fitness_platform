import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/trainer_availability_model.dart';
import 'package:fitness/models/trainer_class_model.dart';
import 'package:fitness/services/trainer_class_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class MyClassesController extends GetxController {
  MyClassesController({
    TrainerClassService? trainerClassService,
    UserService? userService,
  }) : _trainerClassService = trainerClassService ?? TrainerClassService(),
       _userService = userService ?? UserService();

  final TrainerClassService _trainerClassService;
  final UserService? _userService;

  final RxList<Map<String, dynamic>> classes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> completedClasses =
      <Map<String, dynamic>>[].obs;
  final availability = Rxn<TrainerAvailabilityResponse>();
  final selectedSection = MyClassesSection.classes.obs;
  final isHistoryLoading = false.obs;
  final focusedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final isLoading = false.obs;
  final isAvailabilityLoading = false.obs;
  final isSaving = false.obs;
  String? _trainerUserId;

  // Dashboard
  final dashboardStats = Rxn<Map<String, dynamic>>();
  final nextClass = Rxn<Map<String, dynamic>>();
  final todayClasses = <Map<String, dynamic>>[].obs;
  final isDashboardLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClasses();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isDashboardLoading.value = true;
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _trainerClassService.getDashboardStats(),
        _trainerClassService.getNextClass(),
        _trainerClassService.getTodayClasses(dateStr),
      ]);

      dashboardStats.value = results[0] as Map<String, dynamic>;

      final next = results[1] as TrainerClassModel?;
      nextClass.value = next?.toUiMap();

      final today2 = results[2] as List<TrainerClassModel>;
      todayClasses.assignAll(today2.map((c) => c.toUiMap()));
    } catch (_) {
      // Silently fail — dashboard degrades gracefully
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> fetchClasses({bool showError = false}) async {
    try {
      isLoading.value = true;
      final response = await _trainerClassService.getClasses();
      classes.assignAll(response.map((item) => item.toUiMap()));
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Classes failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Classes failed',
          'Could not load classes.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setSection(MyClassesSection section) {
    selectedSection.value = section;
    if (section == MyClassesSection.availability &&
        availability.value == null &&
        !isAvailabilityLoading.value) {
      fetchAvailability(showError: true);
    }
    if (section == MyClassesSection.history &&
        completedClasses.isEmpty &&
        !isHistoryLoading.value) {
      fetchClassHistory(showError: true);
    }
  }

  /// Fetches active + completed classes and splits them by status.
  Future<void> fetchClassHistory({bool showError = false}) async {
    try {
      isHistoryLoading.value = true;
      final all = await _trainerClassService.getClasses(includeCompleted: true);
      // Active classes stay in [classes]; completed go into [completedClasses]
      final active = all.where((c) => c.status.toUpperCase() != 'COMPLETED');
      final completed = all.where((c) => c.status.toUpperCase() == 'COMPLETED');
      classes.assignAll(active.map((c) => c.toUiMap()));
      completedClasses.assignAll(completed.map((c) => c.toUiMap()));
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'History failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'History failed',
          'Could not load class history.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> previousMonth() async {
    final month = focusedMonth.value;
    focusedMonth.value = DateTime(month.year, month.month - 1);
    if (selectedSection.value == MyClassesSection.availability) {
      await fetchAvailability(showError: true);
    }
  }

  Future<void> nextMonth() async {
    final month = focusedMonth.value;
    focusedMonth.value = DateTime(month.year, month.month + 1);
    if (selectedSection.value == MyClassesSection.availability) {
      await fetchAvailability(showError: true);
    }
  }

  Future<void> fetchAvailability({bool showError = false}) async {
    try {
      isAvailabilityLoading.value = true;
      final trainerUserId = await _resolveTrainerUserId();
      if (trainerUserId == null || trainerUserId.isEmpty) {
        throw const ApiException('Trainer ID was not found.');
      }

      availability.value = await _trainerClassService.getTrainerAvailability(
        trainerUserId: trainerUserId,
        month: _monthKey(focusedMonth.value),
      );
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Availability failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      if (showError) {
        showAppSnackbar(
          'Availability failed',
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isAvailabilityLoading.value = false;
    }
  }

  TrainerAvailabilityDay? availabilityForDay(int day) {
    final days = availability.value?.days ?? const <TrainerAvailabilityDay>[];
    for (final item in days) {
      if (item.day == day) return item;

      final parsedDate = DateTime.tryParse(item.date);
      if (parsedDate != null &&
          parsedDate.year == focusedMonth.value.year &&
          parsedDate.month == focusedMonth.value.month &&
          parsedDate.day == day) {
        return item;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> addClass(TrainerClassPayload payload) async {
    try {
      isSaving.value = true;
      final createdClass = await _trainerClassService.createClass(payload);
      Map<String, dynamic>? createdClassMap;
      if (createdClass == null) {
        await fetchClasses();
      } else {
        createdClassMap = createdClass.toUiMap();
        classes.add(createdClassMap);
      }
      showAppSnackbar(
        'Class created',
        'Your class has been published.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return createdClassMap;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Create failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Create failed',
        'Could not create class.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getClassDetails(int index) async {
    if (index < 0 || index >= classes.length) return null;

    final id = classes[index]['id']?.toString();
    if (id == null || id.isEmpty) {
      showAppSnackbar(
        'Class failed',
        'Class ID was not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    try {
      isLoading.value = true;
      return await _trainerClassService.getClassDetails(id);
    } on ApiException catch (error) {
      showAppSnackbar(
        'Class failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Class failed',
        'Could not load class details.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }

    return null;
  }

  Future<bool> updateClass(int index, Map<String, dynamic> payload) async {
    if (index < 0 || index >= classes.length) return false;

    final id = classes[index]['id']?.toString();
    if (id == null || id.isEmpty) {
      showAppSnackbar(
        'Update failed',
        'Class ID was not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (payload.isEmpty) {
      showAppSnackbar(
        'No changes',
        'There are no changes to save.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSaving.value = true;
      await _trainerClassService.updateClass(id: id, payload: payload);
      await fetchClasses();
      if (selectedSection.value == MyClassesSection.availability) {
        await fetchAvailability();
      }
      showAppSnackbar(
        'Class updated',
        'Your changes have been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Update failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Update failed',
        'Could not update class.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }

    return false;
  }

  Future<bool> deleteClass(int index) async {
    if (index < 0 || index >= classes.length) return false;

    final id = classes[index]['id']?.toString();
    if (id == null || id.isEmpty) {
      showAppSnackbar(
        'Delete failed',
        'Class ID was not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSaving.value = true;
      await _trainerClassService.deleteClass(id);
      classes.removeAt(index);
      showAppSnackbar(
        'Class deleted',
        'The class has been cancelled.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Delete failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Delete failed',
        'Could not delete class.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }

    return false;
  }

  Future<String?> _resolveTrainerUserId() async {
    final cached = _trainerUserId;
    if (cached != null && cached.isNotEmpty) return cached;

    final user = await (_userService ?? UserService()).getCurrentUser();
    _trainerUserId = user.trainerUserId ?? user.id;
    return _trainerUserId;
  }

  String _monthKey(DateTime month) {
    final monthText = month.month.toString().padLeft(2, '0');
    return '${month.year}-$monthText';
  }
}

enum MyClassesSection { classes, availability, history }
