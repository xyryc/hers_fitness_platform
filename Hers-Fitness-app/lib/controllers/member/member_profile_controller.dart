import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/storage/local_storage.dart';
import 'package:fitness/models/member_activity_model.dart';
import 'package:fitness/models/referral_model.dart';
import 'package:fitness/models/transaction_model.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:fitness/services/member_assessment_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class MemberProfileController extends GetxController {
  MemberProfileController({
    UserService? userService,
    MemberAssessmentService? assessmentService,
  }) : _userService = userService ?? UserService(),
       _assessmentService = assessmentService ?? MemberAssessmentService();

  final UserService _userService;
  final MemberAssessmentService _assessmentService;
  final _localStorage = LocalStorage();

  final user = Rxn<UserProfileModel>();
  final assessment = Rxn<Map<String, dynamic>>();
  final weeklyActivity = Rxn<MemberWeeklyActivityModel>();
  final monthlyActivity = Rxn<MemberMonthlyActivityModel>();
  final dailyActivity = Rxn<MemberDailyActivityModel>();
  final yearlyActivity = Rxn<MemberYearlyActivityModel>();
  final transactions = RxList<TransactionModel>();
  final isLoading = false.obs;
  final isLoadingActivity = false.obs;
  final isUpdatingProfile = false.obs;
  final isUploadingImage = false.obs;
  final isLoadingTransactions = false.obs;
  final coverPhotoUrl = RxString('');

  @override
  void onInit() {
    super.onInit();
    fetchProfile(showError: true);
    fetchActivity();
    loadCoverPhoto();
  }

  // ─── Computed getters ────────────────────────────────────────────────────

  String get displayName => user.value?.displayName ?? 'Member';

  String get displayLocation =>
      user.value?.displayLocation ?? 'Location not added';

  String get profileImageUrl => user.value?.imageUrl?.trim() ?? '';

  /// Age value from user model or assessment fallback
  String get ageValue {
    final fromUser = user.value?.age;
    if (fromUser != null) return fromUser.toString();
    final fromAssessment = assessment.value?['age']?.toString();
    if (fromAssessment != null &&
        fromAssessment.isNotEmpty &&
        fromAssessment != 'null') {
      return fromAssessment;
    }
    return '--';
  }

  /// Age unit fallback
  String get ageUnit => 'yrs';

  /// Weight value from user model or assessment fallback
  String get weightValue {
    final w = user.value?.weight;
    if (w != null) return w.toString();
    final fromAssessment = assessment.value?['weight']?.toString();
    if (fromAssessment != null &&
        fromAssessment.isNotEmpty &&
        fromAssessment != 'null') {
      return fromAssessment;
    }
    return '--';
  }

  /// Weight unit from user model or fallback
  String get weightUnit => user.value?.weightUnit?.toUpperCase() ?? 'KG';

  String get age => '$ageValue $ageUnit';

  String get weight => '$weightValue $weightUnit';

  /// Diet preference from user model or assessment fallback, formatted for display
  String get dietPreference {
    final raw =
        user.value?.dietPreference ??
        assessment.value?['dietPreference']?.toString();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null')
      return 'Not Set';
    return raw
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  int get weeklyCompletedSessions =>
      weeklyActivity.value?.totalCompletedSessions ?? 0;

  int get yearlyCompletedSessions =>
      monthlyActivity.value?.totalCompletedSessions ?? 0;

  // ─── Cover photo ─────────────────────────────────────────────────────────

  Future<void> loadCoverPhoto() async {
    // First check server value from user model
    final serverUrl = user.value?.coverPhotoUrl;
    if (serverUrl != null && serverUrl.isNotEmpty) {
      coverPhotoUrl.value = serverUrl;
      return;
    }
    // Fallback: locally cached path
    final path = await _localStorage.getMemberCoverPhoto();
    if (path != null) {
      coverPhotoUrl.value = path;
    }
  }

  /// Pick cover photo from gallery and upload to server
  Future<void> pickCoverPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    try {
      isUploadingImage.value = true;
      final updated = await _userService.uploadImages(
        coverImage: File(image.path),
      );
      user.value = updated;
      final newUrl = updated.coverPhotoUrl;
      if (newUrl != null && newUrl.isNotEmpty) {
        coverPhotoUrl.value = newUrl;
        await _localStorage.saveMemberCoverPhoto(newUrl);
      } else {
        // Store local path as fallback
        coverPhotoUrl.value = image.path;
        await _localStorage.saveMemberCoverPhoto(image.path);
      }
    } on ApiException catch (e) {
      showAppSnackbar(
        'Upload failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Still show locally
      coverPhotoUrl.value = image.path;
      await _localStorage.saveMemberCoverPhoto(image.path);
    } catch (_) {
      coverPhotoUrl.value = image.path;
      await _localStorage.saveMemberCoverPhoto(image.path);
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Pick profile image from gallery and upload to server
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    try {
      isUploadingImage.value = true;
      final updated = await _userService.uploadImages(
        profileImage: File(image.path),
      );
      user.value = updated;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Upload failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Upload failed',
        'Could not upload profile image.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ─── Profile fetch / update ───────────────────────────────────────────────

  Future<void> fetchAssessment({bool showError = false}) async {
    try {
      final response = await _assessmentService.getAssessment();
      if (response != null) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic>) {
          assessment.value = data;
        }
      }
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Assessment failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (showError) {
        showAppSnackbar(
          'Assessment failed',
          'Could not load assessment information.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> fetchProfile({bool showError = false}) async {
    try {
      isLoading.value = true;
      user.value = await _userService.getCurrentUser();
      // Sync cover photo from server
      final serverCover = user.value?.coverPhotoUrl;
      if (serverCover != null && serverCover.isNotEmpty) {
        coverPhotoUrl.value = serverCover;
      }
      await fetchAssessment(showError: showError);
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Profile failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Profile failed',
          'Could not load profile information.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    try {
      isUpdatingProfile.value = true;
      user.value = await _userService.updateProfile(request);
      showAppSnackbar(
        'Profile updated',
        'Your profile has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Update failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      showAppSnackbar(
        'Update failed',
        'Could not save profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  // ─── Activity ─────────────────────────────────────────────────────────────

  Future<void> fetchActivity({
    int? year,
    DateTime? weekDate,
    bool showError = false,
  }) async {
    final activityYear = year ?? DateTime.now().year;
    try {
      isLoadingActivity.value = true;
      final results = await Future.wait([
        _userService.getMemberWeeklyActivity(date: weekDate),
        _userService.getMemberMonthlyActivity(year: activityYear),
      ]);
      weeklyActivity.value = results[0] as MemberWeeklyActivityModel;
      monthlyActivity.value = results[1] as MemberMonthlyActivityModel;
    } on ApiException catch (error) {
      weeklyActivity.value ??= MemberWeeklyActivityModel.empty(weekDate);
      monthlyActivity.value ??= MemberMonthlyActivityModel.empty(activityYear);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      weeklyActivity.value ??= MemberWeeklyActivityModel.empty(weekDate);
      monthlyActivity.value ??= MemberMonthlyActivityModel.empty(activityYear);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          'Could not load activity data.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingActivity.value = false;
    }
  }

  Future<void> fetchMonthlyActivity(int year, {bool showError = false}) async {
    try {
      isLoadingActivity.value = true;
      monthlyActivity.value = await _userService.getMemberMonthlyActivity(
        year: year,
      );
    } on ApiException catch (error) {
      monthlyActivity.value ??= MemberMonthlyActivityModel.empty(year);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      monthlyActivity.value ??= MemberMonthlyActivityModel.empty(year);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          'Could not load activity data.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingActivity.value = false;
    }
  }

  Future<void> fetchDailyActivity({
    required int month,
    required int year,
    bool showError = false,
  }) async {
    try {
      isLoadingActivity.value = true;
      dailyActivity.value = await _userService.getMemberDailyActivity(
        month: month,
        year: year,
      );
    } on ApiException catch (error) {
      dailyActivity.value ??= MemberDailyActivityModel.empty(month, year);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      dailyActivity.value ??= MemberDailyActivityModel.empty(month, year);
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          'Could not load daily activity.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingActivity.value = false;
    }
  }

  Future<void> fetchYearlyActivity({bool showError = false}) async {
    try {
      isLoadingActivity.value = true;
      yearlyActivity.value = await _userService.getMemberYearlyActivity();
    } on ApiException catch (error) {
      yearlyActivity.value ??= MemberYearlyActivityModel.empty();
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      yearlyActivity.value ??= MemberYearlyActivityModel.empty();
      if (showError) {
        showAppSnackbar(
          'Activity failed',
          'Could not load yearly activity.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingActivity.value = false;
    }
  }

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<void> fetchTransactions({bool showError = false}) async {
    try {
      isLoadingTransactions.value = true;
      transactions.value = await _userService.getTransactions();
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Transactions failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Transactions failed',
          'Could not load transactions.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  // ─── Referral ─────────────────────────────────────────────────────────────

  Future<ReferralModel?> getReferral() async {
    try {
      return await _userService.getReferral();
    } on ApiException catch (e) {
      showAppSnackbar(
        'Referral failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (_) {
      showAppSnackbar(
        'Referral failed',
        'Could not load referral information.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // ─── Account deletion ─────────────────────────────────────────────────────

  Future<bool> deleteAccount() async {
    try {
      await _userService.deleteAccount();
      return true;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Delete failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      showAppSnackbar(
        'Delete failed',
        'Could not delete account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
