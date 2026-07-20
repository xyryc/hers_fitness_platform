import 'package:flutter_svg/svg.dart';
import '../../Base/ProfilePicPicker/profile_pic_picker.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/auth/trainer_register_controller.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/AppColor/app_colors.dart';
import '../../../utils/AppTextStyle/app_text_styles.dart';
import '../../Base/CustomTextfield/CustomTextfield.dart';

class TrainerSignUpScreen extends StatefulWidget {
  const TrainerSignUpScreen({super.key});

  @override
  State<TrainerSignUpScreen> createState() => _TrainerSignUpScreenState();
}

class _TrainerSignUpScreenState extends State<TrainerSignUpScreen> {
  late final TrainerRegisterController registerController;
  int strengthLevel = 0;

  @override
  void initState() {
    super.initState();
    registerController = Get.isRegistered<TrainerRegisterController>()
        ? Get.find<TrainerRegisterController>()
        : Get.put(TrainerRegisterController());

    registerController.passwordController.addListener(_checkPasswordStrength);
    registerController.confirmPasswordController.addListener(
      _refreshPasswordMatch,
    );
  }

  @override
  void dispose() {
    registerController.passwordController.removeListener(
      _checkPasswordStrength,
    );
    registerController.confirmPasswordController.removeListener(
      _refreshPasswordMatch,
    );
    super.dispose();
  }

  void _refreshPasswordMatch() {
    setState(() {});
  }

  bool get _showPasswordMismatch {
    return registerController.confirmPasswordController.text.isNotEmpty &&
        registerController.passwordController.text !=
            registerController.confirmPasswordController.text;
  }

  void _checkPasswordStrength() {
    String text = registerController.passwordController.text;
    setState(() {
      if (text.isEmpty) {
        strengthLevel = 0;
      } else if (text.length <= 3) {
        strengthLevel = 1;
      } else if (text.length <= 6) {
        strengthLevel = 2;
      } else if (text.length <= 8) {
        strengthLevel = 3;
      } else {
        strengthLevel = 4;
      }
    });
  }

  String getStrengthText() {
    switch (strengthLevel) {
      case 1:
        return "Weak password! Let's add more strength!";
      case 2:
        return "Good password! Try a mix of characters!";
      case 3:
      case 4:
        return "Amazing strength! Let's continue!";
      default:
        return "";
    }
  }

  Color getStrengthColor(int level) {
    if (strengthLevel == 0) return const Color(0xFFE5E7EB);
    if (strengthLevel == 1) return const Color(0xFFF34F4F); // Red
    if (strengthLevel == 2) return Colors.orange; // Yellow/Orange
    if (strengthLevel >= 3) return const Color(0xFF5BA71B); // Green
    return const Color(0xFFE5E7EB);
  }

  Widget _buildBar(int barIndex) {
    bool isActive = strengthLevel >= barIndex;
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive
              ? getStrengthColor(barIndex)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AppText(
        text,
        style: AppTextStyles.base16Medium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    String? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(
            hint,
            style: AppTextStyles.sm14Regular.copyWith(
              color: const Color(0xFF9CA3AF),
            ),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ),
            filled: true,
            fillColor: Colors.transparent,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      prefixIcon,
                      width: 20.w,
                      height: 20.w,
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.actionPrimary,
                width: 1.5,
              ),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: AppTextStyles.base16Medium.copyWith(
                  color: AppColors.DarkBlue,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTagInput({
    required String label,
    required String hint,
    required RxList<String> tags,
    required TextEditingController controller,
    required Function(String) onAdd,
    required Function(String) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Obx(
          () => TextFormField(
            controller: controller,
            onFieldSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                onAdd(value);
              }
            },
            style: AppTextStyles.base16Medium.copyWith(
              color: AppColors.DarkBlue,
            ),
            decoration: InputDecoration(
              hintText: tags.isEmpty ? hint : '',
              hintStyle: AppTextStyles.sm14Regular.copyWith(
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: tags.isEmpty
                  ? null
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tag,
                                      style: AppTextStyles.sm14Medium.copyWith(
                                        color: AppColors.actionPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    GestureDetector(
                                      onTap: () => onDelete(tag),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: AppColors.actionPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: 12.w, bottom: 12.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 4.w),
                        AppText(
                          "${tags.length}/10",
                          style: AppTextStyles.sm14Regular.copyWith(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.actionPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _getDeliveryModeValue(String text) {
    final t = text.trim().toUpperCase();
    if (t == 'ONLINE') return 'Online';
    if (t == 'OFFLINE' || t == 'IN PERSON') return 'In person';
    if (t == 'BOTH') return 'Both';
    if (['Online', 'In person', 'Both'].contains(text)) return text;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, -1.0),
                radius: 2.5,
                colors: [
                  const Color(0xFFFFA6B4).withValues(alpha: 0.5),
                  const Color(0xFFFFE0B9).withValues(alpha: 0.25),
                  Colors.white,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Center(
                    child: Image.asset(
                      "assets/images/welcomeLogo.png",
                      height: 80.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Profile picture picker
                  Center(
                    child: ProfilePicPicker(
                      onImagePicked: registerController.setProfileImage,
                    ),
                  ),
                  SizedBox(height: 40.h),

                  _buildLabel("Enter your name"),
                  CustomTextField(
                    hintText: 'Enter your name',
                    controller: registerController.nameController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/personIcon.svg",
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Enter your email"),
                  CustomTextField(
                    hintText: 'Enter your E-mail',
                    controller: registerController.emailController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/emailIcon.svg",
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Phone number"),
                  CustomTextField(
                    hintText: '(229) 555-0109',
                    controller: registerController.phoneController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/phoneIcon.svg",
                  ),
                  SizedBox(height: 16.h),

                  _buildDropdown(
                    label: "State",
                    hint: "Select your state",
                    items: const [
                      'Alabama',
                      'Alaska',
                      'Arizona',
                      'Arkansas',
                      'California',
                      'Colorado',
                      'Connecticut',
                      'Delaware',
                      'Florida',
                      'Georgia',
                      'Hawaii',
                      'Idaho',
                      'Illinois',
                      'Indiana',
                      'Iowa',
                      'Kansas',
                      'Kentucky',
                      'Louisiana',
                      'Maine',
                      'Maryland',
                      'Massachusetts',
                      'Michigan',
                      'Minnesota',
                      'Mississippi',
                      'Missouri',
                      'Montana',
                      'Nebraska',
                      'Nevada',
                      'New Hampshire',
                      'New Jersey',
                      'New Mexico',
                      'New York',
                      'North Carolina',
                      'North Dakota',
                      'Ohio',
                      'Oklahoma',
                      'Oregon',
                      'Pennsylvania',
                      'Rhode Island',
                      'South Carolina',
                      'South Dakota',
                      'Tennessee',
                      'Texas',
                      'Utah',
                      'Vermont',
                      'Virginia',
                      'Washington',
                      'West Virginia',
                      'Wisconsin',
                      'Wyoming',
                    ],
                    value:
                        registerController.stateController.text.isEmpty ||
                            !const [
                              'Alabama',
                              'Alaska',
                              'Arizona',
                              'Arkansas',
                              'California',
                              'Colorado',
                              'Connecticut',
                              'Delaware',
                              'Florida',
                              'Georgia',
                              'Hawaii',
                              'Idaho',
                              'Illinois',
                              'Indiana',
                              'Iowa',
                              'Kansas',
                              'Kentucky',
                              'Louisiana',
                              'Maine',
                              'Maryland',
                              'Massachusetts',
                              'Michigan',
                              'Minnesota',
                              'Mississippi',
                              'Missouri',
                              'Montana',
                              'Nebraska',
                              'Nevada',
                              'New Hampshire',
                              'New Jersey',
                              'New Mexico',
                              'New York',
                              'North Carolina',
                              'North Dakota',
                              'Ohio',
                              'Oklahoma',
                              'Oregon',
                              'Pennsylvania',
                              'Rhode Island',
                              'South Carolina',
                              'South Dakota',
                              'Tennessee',
                              'Texas',
                              'Utah',
                              'Vermont',
                              'Virginia',
                              'Washington',
                              'West Virginia',
                              'Wisconsin',
                              'Wyoming',
                            ].contains(registerController.stateController.text)
                        ? null
                        : registerController.stateController.text,
                    onChanged: (val) {
                      setState(() {
                        registerController.stateController.text = val ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("City"),
                  CustomTextField(
                    hintText: 'Syracuse, Connecticut',
                    controller: registerController.locationController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/locationIcon.svg",
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Personal Bio"),
                  Stack(
                    children: [
                      CustomTextField(
                        hintText: 'e.g. NASM CPT',
                        controller: registerController.bioController,
                        filColor: Colors.transparent,
                        borderColor: const Color(0xFFE0E0E0),
                        borderRadius: 12,
                        maxLines: 4,
                        hintStyle: AppTextStyles.sm14Regular.copyWith(
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPaddingVertical: 12,
                        onChanged: (val) {
                          if (val.length > 250) {
                            registerController.bioController.text = val
                                .substring(0, 250);
                            registerController.bioController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: registerController
                                        .bioController
                                        .text
                                        .length,
                                  ),
                                );
                          }
                          setState(() {});
                        },
                      ),
                      Positioned(
                        bottom: 12.h,
                        right: 12.w,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(width: 4.w),
                            AppText(
                              "${registerController.bioController.text.length}/250",
                              style: AppTextStyles.sm14Regular.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  _buildTagInput(
                    label: "What fitness classes do you teach?",
                    hint: "Strength Training|",
                    tags: registerController.classesTaughtTags,
                    controller: registerController.classesTaughtController,
                    onAdd: registerController.addClassTag,
                    onDelete: registerController.removeClassTag,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("How long have you been an instructor?"),
                  CustomTextField(
                    hintText: '2yr',
                    controller:
                        registerController.instructorExperienceController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/calendarIcon.svg",
                  ),
                  SizedBox(height: 16.h),

                  _buildTagInput(
                    label: "What certifications/qualifications do you have?",
                    hint: "e.g. NASM CPT",
                    tags: registerController.certificationsTags,
                    controller: registerController.certificationsController,
                    onAdd: registerController.addCertificationTag,
                    onDelete: registerController.removeCertificationTag,
                  ),
                  SizedBox(height: 16.h),

                  _buildDropdown(
                    label: "Do you host classes online or in person?",
                    hint: "e.g. Online, In person, or Both",
                    items: const ['Online', 'In person', 'Both'],
                    value: _getDeliveryModeValue(
                      registerController.classDeliveryModeController.text,
                    ),
                    onChanged: (val) {
                      setState(() {
                        registerController.classDeliveryModeController.text =
                            val ?? 'Both';
                      });
                    },
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Password"),
                  CustomTextField(
                    hintText: '******',
                    controller: registerController.passwordController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/lock.svg",
                    isPassword: true,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Confirm Password"),
                  CustomTextField(
                    hintText: '******',
                    controller: registerController.confirmPasswordController,
                    filColor: Colors.transparent,
                    borderColor: const Color(0xFFE0E0E0),
                    borderRadius: 12,
                    hintStyle: AppTextStyles.sm14Regular.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: "assets/icons/lock.svg",
                    isPassword: true,
                  ),
                  if (_showPasswordMismatch) ...[
                    SizedBox(height: 8.h),
                    AppText(
                      'Passwords do not match.',
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: AppColors.statusError,
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),

                  // Password strength indicator
                  Row(
                    children: [
                      _buildBar(1),
                      SizedBox(width: 8.w),
                      _buildBar(2),
                      SizedBox(width: 8.w),
                      _buildBar(3),
                      SizedBox(width: 8.w),
                      _buildBar(4),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (strengthLevel > 0)
                    AppText(
                      getStrengthText(),
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  SizedBox(height: 32.h),

                  Obx(() {
                    final canSubmit = registerController.isFormValid.value;
                    return AppButton(
                      text: "Sign up",
                      isLoading: registerController.isLoading.value,
                      backgroundColor: canSubmit
                          ? AppColors.actionSecondary
                          : AppColors.actionPrimaryDisabled,
                      onTap: registerController.isLoading.value || !canSubmit
                          ? () {}
                          : registerController.continueToIdentityVerification,
                    );
                  }),

                  SizedBox(height: 24.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        "Already have an account? ",
                        style: AppTextStyles.sm14Regular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Get.toNamed(AppRoutes.signInScreen);
                        },
                        child: AppText(
                          "Login",
                          style: AppTextStyles.sm14SemiBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
