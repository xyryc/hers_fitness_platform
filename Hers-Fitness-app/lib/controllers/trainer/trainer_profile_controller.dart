import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/storage/local_storage.dart';
import 'package:fitness/models/payout_status_model.dart';
import 'package:fitness/models/trainer_earnings_model.dart';
import 'package:fitness/models/trainer_top_class_model.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:fitness/services/trainer_class_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class TrainerProfileController extends GetxController {
  TrainerProfileController({
    UserService? userService,
    TrainerClassService? trainerClassService,
  }) : _userService = userService ?? UserService(),
       _trainerClassService = trainerClassService ?? TrainerClassService();

  final UserService _userService;
  final TrainerClassService _trainerClassService;
  final _localStorage = LocalStorage();

  // ── User profile ────────────────────────────────────────────────────────
  final user = Rxn<UserProfileModel>();
  final isLoading = false.obs;
  final isChangingPassword = false.obs;
  final coverPhotoUrl = RxString('');

  // ── Dashboard stats ──────────────────────────────────────────────────────
  final dashboardStats = Rxn<Map<String, dynamic>>();
  final isLoadingStats = false.obs;

  // ── Earnings chart ───────────────────────────────────────────────────────
  final earnings = Rxn<TrainerEarningsModel>();
  final isLoadingEarnings = false.obs;

  // ── Top classes ──────────────────────────────────────────────────────────
  final topClasses = RxList<TrainerTopClassModel>();
  final isLoadingTopClasses = false.obs;

  // ── Payout (Stripe Connect) ───────────────────────────────────────────────
  final isLoadingPayout = false.obs;
  final isGeneratingOnboardingLink = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    loadCoverPhoto();
    fetchDashboardStats();
    fetchEarnings(period: 'monthly', year: DateTime.now().year);
    fetchTopClasses();
  }

  // ── Computed getters ─────────────────────────────────────────────────────

  bool get payoutReady => user.value?.payoutReady ?? false;

  String get displayName => user.value?.displayName ?? 'Trainer';
  String get displayLocation =>
      user.value?.displayLocation ?? 'Location not added';
  String get profileImageUrl => user.value?.imageUrl?.trim() ?? '';

  /// Formatted stat values from dashboardStats
  String get totalClasses =>
      dashboardStats.value?['totalClasses']?.toString() ?? '--';

  String get totalRevenue {
    final raw = dashboardStats.value?['totalRevenue'];
    if (raw == null) return '--';
    final v = double.tryParse(raw.toString());
    if (v == null) return '--';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(v);
  }

  String get totalAttendance =>
      dashboardStats.value?['totalAttendance']?.toString() ?? '--';

  String get avgClassSize =>
      dashboardStats.value?['avgClassSize']?.toString() ?? '--';

  // ── Cover photo ──────────────────────────────────────────────────────────

  Future<void> loadCoverPhoto() async {
    final serverUrl = user.value?.coverPhotoUrl;
    if (serverUrl != null && serverUrl.isNotEmpty) {
      coverPhotoUrl.value = serverUrl;
      return;
    }
    final path = await _localStorage.getTrainerCoverPhoto();
    if (path != null) coverPhotoUrl.value = path;
  }

  Future<void> pickCoverPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      await _localStorage.saveTrainerCoverPhoto(image.path);
      coverPhotoUrl.value = image.path;
    }
  }

  // ── Profile fetch ────────────────────────────────────────────────────────

  Future<void> fetchProfile({bool showError = false}) async {
    try {
      isLoading.value = true;
      user.value = await _userService.getCurrentUser();
      final serverCover = user.value?.coverPhotoUrl;
      if (serverCover != null && serverCover.isNotEmpty) {
        coverPhotoUrl.value = serverCover;
      }
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
          'Could not load profile.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ── Dashboard stats ──────────────────────────────────────────────────────

  Future<void> fetchDashboardStats({bool showError = false}) async {
    try {
      isLoadingStats.value = true;
      dashboardStats.value = await _trainerClassService.getDashboardStats();
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Stats failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Stats failed',
          'Could not load stats.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingStats.value = false;
    }
  }

  // ── Earnings chart ───────────────────────────────────────────────────────

  /// Fetch earnings for the given period.
  /// - monthly: pass [year]
  /// - weekly:  pass [date] as 'yyyy-MM-dd'
  /// - yearly:  no extra params needed
  Future<void> fetchEarnings({
    required String period,
    int? year,
    String? date,
  }) async {
    try {
      isLoadingEarnings.value = true;
      earnings.value = await _trainerClassService.getEarnings(
        period: period,
        year: year,
        date: date,
      );
    } on ApiException catch (error) {
      earnings.value ??= TrainerEarningsModel.empty(period);
      if (error.statusCode != 401) {
        showAppSnackbar(
          'Earnings failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      earnings.value ??= TrainerEarningsModel.empty(period);
    } finally {
      isLoadingEarnings.value = false;
    }
  }

  // ── Top classes ──────────────────────────────────────────────────────────

  Future<void> fetchTopClasses({bool showError = false}) async {
    try {
      isLoadingTopClasses.value = true;
      topClasses.value = await _trainerClassService.getTopClasses();
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Top classes failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Top classes failed',
          'Could not load top classes.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingTopClasses.value = false;
    }
  }

  // ── Profile update ────────────────────────────────────────────────────────

  final isUpdatingProfile = false.obs;
  final isUploadingImage = false.obs;

  Future<bool> updateTrainerProfile(UpdateTrainerProfileRequest request) async {
    try {
      isUpdatingProfile.value = true;
      user.value = await _userService.updateTrainerProfile(request);
      showAppSnackbar(
        'Profile updated',
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
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdatingProfile.value = false;
    }
    return false;
  }

  /// Immediately uploads [image] as the trainer's profile photo.
  Future<bool> uploadTrainerProfileImage(File image) async {
    try {
      isUploadingImage.value = true;
      final updated = await _userService.uploadTrainerImages(
        profileImage: image,
      );
      // Merge only the image URL back into the current user model
      if (updated.imageUrl != null) {
        user.value = UserProfileModel(
          id: user.value?.id,
          trainerUserId: user.value?.trainerUserId,
          firstName: user.value?.firstName,
          lastName: user.value?.lastName,
          fullName: user.value?.fullName,
          email: user.value?.email,
          phoneNumber: user.value?.phoneNumber,
          gender: user.value?.gender,
          role: user.value?.role,
          imageUrl: updated.imageUrl,
          state: user.value?.state,
          location: user.value?.location,
          bio: user.value?.bio,
          accountStatus: user.value?.accountStatus,
          age: user.value?.age,
          weight: user.value?.weight,
          weightUnit: user.value?.weightUnit,
          dietPreference: user.value?.dietPreference,
          coverPhotoUrl: user.value?.coverPhotoUrl,
          fitnessClasses: user.value?.fitnessClasses,
          instructorDuration: user.value?.instructorDuration,
          certifications: user.value?.certifications,
          sessionFormat: user.value?.sessionFormat,
          baseLocationLat: user.value?.baseLocationLat,
          baseLocationLng: user.value?.baseLocationLng,
          stripeConnectAccountId: user.value?.stripeConnectAccountId,
          stripeConnectOnboardingComplete:
              user.value?.stripeConnectOnboardingComplete,
          stripeChargesEnabled: user.value?.stripeChargesEnabled,
          stripePayoutsEnabled: user.value?.stripePayoutsEnabled,
          stripeDetailsSubmitted: user.value?.stripeDetailsSubmitted,
          stripeConnectUpdatedAt: user.value?.stripeConnectUpdatedAt,
          payoutReady: user.value?.payoutReady,
        );
      }
      showAppSnackbar(
        'Photo updated',
        'Your profile photo has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Upload failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Upload failed',
        'Could not upload photo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingImage.value = false;
    }
    return false;
  }

  // ── Payout ────────────────────────────────────────────────────────────────

  /// Fetches live payout status from Stripe and updates [user].
  Future<void> fetchPayoutStatus() async {
    try {
      isLoadingPayout.value = true;
      final status = await _userService.getTrainerPayoutStatus();
      final current = user.value;
      if (current != null) {
        user.value = UserProfileModel(
          id: current.id,
          trainerUserId: current.trainerUserId,
          firstName: current.firstName,
          lastName: current.lastName,
          fullName: current.fullName,
          email: current.email,
          phoneNumber: current.phoneNumber,
          gender: current.gender,
          role: current.role,
          imageUrl: current.imageUrl,
          state: current.state,
          location: current.location,
          bio: current.bio,
          accountStatus: current.accountStatus,
          age: current.age,
          weight: current.weight,
          weightUnit: current.weightUnit,
          dietPreference: current.dietPreference,
          coverPhotoUrl: current.coverPhotoUrl,
          fitnessClasses: current.fitnessClasses,
          instructorDuration: current.instructorDuration,
          certifications: current.certifications,
          sessionFormat: current.sessionFormat,
          baseLocationLat: current.baseLocationLat,
          baseLocationLng: current.baseLocationLng,
          stripeConnectAccountId: status.stripeConnectAccountId,
          stripeConnectOnboardingComplete: status.onboardingComplete,
          stripeChargesEnabled: status.chargesEnabled,
          stripePayoutsEnabled: status.payoutsEnabled,
          stripeDetailsSubmitted: status.detailsSubmitted,
          stripeConnectUpdatedAt: status.updatedAt,
          payoutReady: status.payoutReady,
        );
      }
    } on ApiException catch (error) {
      showAppSnackbar(
        'Payout status failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Payout status failed',
        'Could not refresh payout status.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingPayout.value = false;
    }
  }

  /// Calls the backend to generate a Stripe Connect onboarding URL.
  /// Returns the URL string on success, null on failure.
  Future<PayoutStatusModel?> generateOnboardingLink() async {
    try {
      isGeneratingOnboardingLink.value = true;
      return await _userService.generateTrainerOnboardingLink();
    } on ApiException catch (error) {
      showAppSnackbar(
        'Setup failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (_) {
      showAppSnackbar(
        'Setup failed',
        'Could not start payout setup.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isGeneratingOnboardingLink.value = false;
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────

  final isDeletingAccount = false.obs;

  Future<bool> deleteAccount() async {
    try {
      isDeletingAccount.value = true;
      await _userService.deleteTrainerAccount();
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
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeletingAccount.value = false;
    }
    return false;
  }

  // ── Password ─────────────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      isChangingPassword.value = true;
      await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      showAppSnackbar(
        'Password updated',
        'Your password has been changed successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Password update failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Password update failed',
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }
}
