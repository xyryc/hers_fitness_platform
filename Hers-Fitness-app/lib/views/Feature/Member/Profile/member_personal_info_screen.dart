import 'package:fitness/controllers/member/member_profile_controller.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class MemberPersonalInfoScreen extends StatefulWidget {
  const MemberPersonalInfoScreen({super.key});

  @override
  State<MemberPersonalInfoScreen> createState() =>
      _MemberPersonalInfoScreenState();
}

class _MemberPersonalInfoScreenState extends State<MemberPersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedWeightUnit;
  String? _selectedDiet;

  late final MemberProfileController _profileController;
  Worker? _profileWorker;

  static const _weightUnits = ['KG', 'LBS'];
  static const _dietOptions = [
    'PLANT_BASED_VEGAN',
    'CARBO_DIET',
    'SPECIALIZED_PALEO_KETO',
    'TRADITIONAL_FRUIT_DIET',
  ];

  static const _dietLabels = {
    'PLANT_BASED_VEGAN': 'Plant Based / Vegan',
    'CARBO_DIET': 'Carbo Diet',
    'SPECIALIZED_PALEO_KETO': 'Paleo / Keto',
    'TRADITIONAL_FRUIT_DIET': 'Traditional / Fruit Diet',
  };

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<MemberProfileController>()
        ? Get.find<MemberProfileController>()
        : Get.put(MemberProfileController());
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
    _locationController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _populateProfile(UserProfileModel? user) {
    if (user == null) return;
    _nameController.text = user.displayName;
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _stateController.text = user.state ?? '';
    _locationController.text = user.location ?? '';
    if (user.age != null) _ageController.text = user.age.toString();
    if (user.weight != null) _weightController.text = user.weight.toString();
    if (mounted) {
      setState(() {
        _selectedWeightUnit = user.weightUnit ?? 'KG';
        _selectedDiet = user.dietPreference;
      });
    }
  }

  Future<void> _onSave() async {
    final success = await _profileController.updateProfile(
      UpdateProfileRequest(
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
        age: int.tryParse(_ageController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        weightUnit: _selectedWeightUnit,
        dietPreference: _selectedDiet,
      ),
    );
    if (success && mounted) Get.back();
  }

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
                  _buildLabel("Full Name"),
                  CustomTextField(
                    prefixIcon: "assets/icons/personIcon.svg",
                    hintText: "Enter your name",
                    controller: _nameController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Email Address"),
                  CustomTextField(
                    hintText: "Enter your E-mail",
                    controller: _emailController,
                    prefixIcon: "assets/icons/emailIcon.svg",
                    enabled: false, // email not editable via this endpoint
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Phone number"),
                  CustomTextField(
                    prefixIcon: Icon(Icons.phone_outlined, size: 20.w),
                    hintText: "(229) 555-0109",
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Your state"),
                  CustomTextField(
                    hintText: "Enter your state",
                    controller: _stateController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Location"),
                  CustomTextField(
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20.w),
                    hintText: "Syracuse, Connecticut",
                    controller: _locationController,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Age"),
                  CustomTextField(
                    prefixIcon: Icon(Icons.cake_outlined, size: 20.w),
                    hintText: "Enter your age",
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Weight"),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: Icon(
                            Icons.monitor_weight_outlined,
                            size: 20.w,
                          ),
                          hintText: "Enter your weight",
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _buildSegmentedControl(
                        options: _weightUnits,
                        selected: _selectedWeightUnit ?? 'KG',
                        onChanged: (v) =>
                            setState(() => _selectedWeightUnit = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Diet Preference"),
                  _buildDropdown(
                    hint: "Select diet preference",
                    value: _selectedDiet,
                    items: _dietOptions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              _dietLabels[d] ?? d,
                              style: AppTextStyles.sm14Regular.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDiet = v),
                  ),
                  SizedBox(height: 32.h),

                  Obx(() {
                    final saving = _profileController.isUpdatingProfile.value;
                    return AppButton(
                      onTap: saving ? () {} : _onSave,
                      text: saving ? "Saving…" : "Save Settings",
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

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 230.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pink Background
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
                        "Personal Info",
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
          // Profile Image
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
          // Edit Icon — upload profile image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() {
                final uploading = _profileController.isUploadingImage.value;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: uploading ? null : _profileController.pickProfileImage,
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
                              "assets/icons/editIcon.svg",
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  Widget _buildSegmentedControl({
    required List<String> options,
    required String selected,
    required void Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.actionPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                opt,
                style: AppTextStyles.sm14Medium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.sm14Regular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
