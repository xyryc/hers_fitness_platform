import 'dart:io';

import 'package:fitness/controllers/trainer/trainer_location_controller.dart';
import 'package:fitness/controllers/trainer/trainer_profile_controller.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _bioController = TextEditingController();
  final _durationController = TextEditingController();
  final _certController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedHostMode;
  final List<String> _hostModeOptions = ['Online', 'In person', 'Both'];
  final List<String> _teachClasses = [];

  late final TrainerProfileController _profileController;
  late final TrainerLocationController _trainerLocationController;
  Worker? _profileWorker;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<TrainerProfileController>()
        ? Get.find<TrainerProfileController>()
        : Get.put(TrainerProfileController());
    _trainerLocationController = Get.isRegistered<TrainerLocationController>()
        ? Get.find<TrainerLocationController>()
        : Get.put(TrainerLocationController());

    _profileWorker = ever<UserProfileModel?>(
      _profileController.user,
      _populateProfile,
    );
    _populateProfile(_profileController.user.value);
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _bioController.dispose();
    _durationController.dispose();
    _certController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ── Populate from profile ──────────────────────────────────────────────────

  void _populateProfile(UserProfileModel? user) {
    if (user == null || !mounted) return;
    _nameController.text = user.displayName;
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _stateController.text = user.state ?? '';
    _locationController.text = user.location ?? '';
    _bioController.text = user.bio ?? '';
    _durationController.text = user.instructorDuration ?? '';
    _certController.text = user.certifications ?? '';

    if (user.baseLocationLat != null) {
      _latController.text = user.baseLocationLat.toString();
    }
    if (user.baseLocationLng != null) {
      _lngController.text = user.baseLocationLng.toString();
    }

    if (mounted) {
      setState(() {
        _selectedHostMode = user.sessionFormat;
        if (user.fitnessClasses != null) {
          _teachClasses
            ..clear()
            ..addAll(user.fitnessClasses!);
        }
      });
    }
  }

  // ── Save profile ───────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final success = await _profileController.updateTrainerProfile(
      UpdateTrainerProfileRequest(
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        fitnessClasses: _teachClasses.isNotEmpty
            ? List.from(_teachClasses)
            : null,
        instructorDuration: _durationController.text.trim().isNotEmpty
            ? _durationController.text.trim()
            : null,
        certifications: _certController.text.trim().isNotEmpty
            ? _certController.text.trim()
            : null,
        sessionFormat: _selectedHostMode,
      ),
    );
    if (success && mounted) Get.back();
  }

  // ── Base location save ─────────────────────────────────────────────────────

  Future<void> _saveBaseLocation() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      showAppSnackbar(
        'Invalid coordinates',
        'Please enter valid latitude and longitude values.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      showAppSnackbar(
        'Invalid coordinates',
        'Latitude must be -90 to 90 and longitude must be -180 to 180.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _trainerLocationController.setBaseLocation(lat: lat, lng: lng);
  }

  Future<void> _useCurrentLocationAsBase() async {
    await _trainerLocationController.setCurrentLocationAsBase();
  }

  // ── Image pick — uploads immediately ──────────────────────────────────────

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.actionPrimary,
              ),
              title: AppText('Gallery', style: AppTextStyles.base16Medium),
              onTap: () {
                Get.back();
                _selectAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_outlined,
                color: AppColors.actionPrimary,
              ),
              title: AppText('Camera', style: AppTextStyles.base16Medium),
              onTap: () {
                Get.back();
                _selectAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectAndUploadImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _profileController.uploadTrainerProfileImage(File(picked.path));
  }

  // ── Tag helpers ───────────────────────────────────────────────────────────

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty &&
        _teachClasses.length < 10 &&
        !_teachClasses.contains(trimmed)) {
      setState(() => _teachClasses.add(trimmed));
    }
    _tagController.clear();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name'),
                  CustomTextField(
                    prefixIcon: 'assets/icons/personIcon.svg',
                    hintText: 'Enter your name',
                    controller: _nameController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Email Address'),
                  CustomTextField(
                    hintText: 'Enter your E-mail',
                    controller: _emailController,
                    prefixIcon: 'assets/icons/emailIcon.svg',
                    enabled: false, // email not editable
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Phone number'),
                  CustomTextField(
                    prefixIcon: Icon(Icons.phone_outlined, size: 20.w),
                    hintText: '(229) 555-0109',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Your state'),
                  CustomTextField(
                    hintText: 'Enter your state',
                    controller: _stateController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Personal Bio'),
                  CustomTextField(
                    maxLines: 4,
                    hintText: 'Tell members about yourself…',
                    controller: _bioController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('What fitness classes do you teach?'),
                  _buildTeachClassesField(),
                  SizedBox(height: 16.h),

                  _buildLabel('How long have you been an instructor?'),
                  CustomTextField(
                    prefixIcon: Icon(Icons.calendar_month_outlined, size: 20.w),
                    hintText: '2yr',
                    controller: _durationController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel(
                    'What certifications/qualifications do you have?',
                  ),
                  CustomTextField(
                    maxLines: 4,
                    hintText: 'e.g. NASM CPT',
                    controller: _certController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Do you host classes online or in person?'),
                  _buildDropdown(),
                  SizedBox(height: 16.h),

                  _buildLabel('Location'),
                  CustomTextField(
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20.w),
                    hintText: 'Syracuse, Connecticut',
                    controller: _locationController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel('Base Coordinates'),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 20.w),
                          hintText: 'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          controller: _latController,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: Icon(Icons.pin_drop, size: 20.w),
                          hintText: 'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          controller: _lngController,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => AppButton(
                      onTap: _trainerLocationController.isUpdating.value
                          ? () {}
                          : _saveBaseLocation,
                      text: 'Save Base Location',
                      isLoading: _trainerLocationController.isUpdating.value,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(
                    () => GestureDetector(
                      onTap: _trainerLocationController.isUpdating.value
                          ? null
                          : _useCurrentLocationAsBase,
                      child: Container(
                        height: 48.h,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.borderPrimary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 18.sp,
                              color: AppColors.actionPrimary,
                            ),
                            SizedBox(width: 8.w),
                            AppText(
                              'Use Current Location',
                              style: AppTextStyles.sm14SemiBold.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // ── Save Settings button ───────────────────────────────────
                  Obx(() {
                    final saving = _profileController.isUpdatingProfile.value;
                    return AppButton(
                      onTap: saving ? () {} : _onSave,
                      text: saving ? 'Saving…' : 'Save Settings',
                      isLoading: saving,
                    );
                  }),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 230.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pink background
          Container(
            height: 160.h,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20.w,
              MediaQuery.of(context).padding.top + 10.h,
              20.w,
              0,
            ),
            decoration: BoxDecoration(
              color: AppColors.actionPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Center(
                      child: AppText(
                        'Personal Info',
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: Colors.white,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 44.w),
              ],
            ),
          ),
          // Profile image
          Positioned(
            bottom: 20.h,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() {
                final imageUrl = _profileController.profileImageUrl;
                return Container(
                  width: 87.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    color: AppColors.bgSecondary,
                    image: imageUrl.isEmpty
                        ? null
                        : DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                    border: Border.all(color: Colors.white, width: 2.w),
                  ),
                  child: imageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 38.w,
                        )
                      : null,
                );
              }),
            ),
          ),
          // Edit icon — triggers immediate upload
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() {
                final uploading = _profileController.isUploadingImage.value;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: uploading ? null : _pickProfileImage,
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: uploading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/editIcon.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 18.w,
                              height: 18.w,
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AppText(
        text,
        style: AppTextStyles.sm14Medium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedHostMode,
          isExpanded: true,
          hint: AppText(
            'Online, In person or Both',
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.w,
            color: AppColors.textSecondary,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textPrimary,
          ),
          items: _hostModeOptions
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: AppText(
                    mode,
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedHostMode = v),
        ),
      ),
    );
  }

  Widget _buildTeachClassesField() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.actionPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._teachClasses.map(_buildDynamicTag),
              SizedBox(
                width: 100.w,
                child: TextField(
                  controller: _tagController,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add…',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    if (v.endsWith(' ')) _addTag(v.trim());
                  },
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.description_outlined, size: 14.w, color: Colors.grey),
              SizedBox(width: 4.w),
              AppText(
                '${_teachClasses.length}/10',
                style: AppTextStyles.xs12Regular.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTag(String text) {
    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 6.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text,
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.actionPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => setState(() => _teachClasses.remove(text)),
            child: Icon(
              Icons.close,
              size: 14.w,
              color: AppColors.actionPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
