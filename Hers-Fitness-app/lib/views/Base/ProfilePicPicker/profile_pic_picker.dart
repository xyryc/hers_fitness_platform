import 'dart:io';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/AppColor/app_colors.dart';

class ProfilePicPicker extends StatefulWidget {
  final String? placeholderImage;
  final Function(File) onImagePicked;

  const ProfilePicPicker({
    super.key,
    this.placeholderImage,
    required this.onImagePicked,
  });

  @override
  State<ProfilePicPicker> createState() => _ProfilePicPickerState();
}

class _ProfilePicPickerState extends State<ProfilePicPicker> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: AppColors.actionPrimary,
              ),
              title: AppText('Gallery', style: AppTextStyles.base16Medium),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                  widget.onImagePicked(_imageFile!);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.actionPrimary),
              title: AppText('Camera', style: AppTextStyles.base16Medium),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                  widget.onImagePicked(_imageFile!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImageFile = _imageFile != null;
    final hasPlaceholder =
        widget.placeholderImage != null && widget.placeholderImage!.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              color: hasImageFile ? null : AppColors.bgTertiaryGrey,
              image: hasImageFile
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : (hasPlaceholder
                        ? DecorationImage(
                            image: AssetImage(widget.placeholderImage!),
                            fit: BoxFit.cover,
                          )
                        : null),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: !hasImageFile && !hasPlaceholder
                ? Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 40.w,
                      color: AppColors.iconSecondary,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: -12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
