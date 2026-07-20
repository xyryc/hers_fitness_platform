import 'package:fitness/controllers/common/chat_controller.dart';
import 'package:fitness/controllers/member/trainer_bookmark_controller.dart';
import 'package:fitness/controllers/member/trainer_details_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../Helpers/route.dart';
import '../../common/chat/chat_screen.dart';
import 'widgets/review_card.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrainerDetailsScreen extends StatelessWidget {
  TrainerDetailsScreen({super.key});

  final TrainerDetailsController controller =
      Get.isRegistered<TrainerDetailsController>()
      ? Get.find<TrainerDetailsController>()
      : Get.put(TrainerDetailsController());
  final TrainerBookmarkController bookmarkController =
      Get.isRegistered<TrainerBookmarkController>()
      ? Get.find<TrainerBookmarkController>()
      : Get.put(TrainerBookmarkController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(),
                SizedBox(height: 24.h),
                _buildStatsCard(),
                SizedBox(height: 24.h),
                _buildAvailabilitySection(),
                SizedBox(height: 24.h),
                _buildReviewsSection(),
                SizedBox(height: 24.h),
                _buildBioSection(),
                SizedBox(height: 24.h),
                _buildLocationSection(),
                SizedBox(height: 120.h),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Obx(() {
      final trainer = controller.trainer.value ?? const <String, dynamic>{};
      final imageUrl = trainer['imageUrl']?.toString();
      final displayImage = imageUrl != null && imageUrl.isNotEmpty
          ? imageUrl
          : "https://images.unsplash.com/photo-1518611012118-29a88f5573ce?q=80&w=800&auto=format&fit=crop";
      final name = trainer['name']?.toString() ?? 'Trainer';
      final priceRange = _heroPriceRange(trainer['priceRange']);
      final distance = _heroDistance(trainer['distanceMeters']);

      return Stack(
        children: [
          Container(
            height: 400.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40.r),
              ),
              image: DecorationImage(
                image: NetworkImage(displayImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay Gradient for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Top Buttons
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: CustomAppbar(
                trailing: Obx(() {
                  final isBookmarked = bookmarkController.isBookmarked(trainer);
                  return GestureDetector(
                    onTap: () => bookmarkController.toggleTrainer(trainer),
                    child: SvgPicture.asset(
                      isBookmarked
                          ? "assets/icons/befor_bookmark.svg"
                          : "assets/icons/after_bookmark.svg",
                      width: 52.w,
                      height: 52.w,
                    ),
                  );
                }),
              ),
            ),
          ),
          // Bottom Text Info
          Positioned(
            left: 20.w,
            right: 86.w,
            bottom: 26.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  priceRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Flexible(
                      child: _buildInfoItem(
                        Icons.monitor_heart_outlined,
                        trainer['expertise']?.toString() ?? 'Trainer',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Flexible(
                      child: _buildInfoItem(Icons.near_me_outlined, distance),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Message Button
          Positioned(
            right: 20.w,
            bottom: 30.h,
            child: GestureDetector(
              onTap: _startTrainerChat,
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble,
                  color: Colors.black,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.sp, color: Colors.white.withValues(alpha: 0.8)),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startTrainerChat() async {
    final trainer = controller.trainer.value ?? const <String, dynamic>{};
    final trainerUserId =
        (trainer['trainerUserId']?.toString() ??
                trainer['id']?.toString() ??
                '')
            .trim();
    final trainerName = trainer['name']?.toString();
    final avatarUrl = trainer['imageUrl']?.toString();

    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());
    final contact = await chatController.startConversationWithTrainer(
      trainerUserId: trainerUserId,
      trainerName: trainerName,
      avatarUrl: avatarUrl,
    );

    if (contact != null) {
      Get.to(() => ChatScreen(contact: contact));
    }
  }

  String _heroPriceRange(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'Price unavailable';
    final parts = text.split('-').map((part) {
      final trimmed = part.trim();
      return trimmed.startsWith(r'$') ? trimmed : '\$$trimmed';
    }).toList();
    return '${parts.join(' - ')} / class';
  }

  String _heroDistance(Object? value) {
    final meters = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (meters == null) return 'Distance unavailable';
    if (meters < 1000) return '${meters.round()} meters away';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km away';
  }

  Widget _buildStatsCard() {
    return Obx(() {
      final trainer = controller.trainer.value ?? const <String, dynamic>{};
      final experience = _experienceText(trainer['experience']);
      final reviews = _countText(trainer['reviewCount']);
      final rating = _ratingText(trainer['rating']);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(experience, "Experience"),
            _buildDivider(),
            _buildStatItem(reviews, "Reviews"),
            _buildDivider(),
            _buildStatItem(rating, "Rating"),
          ],
        ),
      );
    });
  }

  String _experienceText(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '0y';
    final number = RegExp(r'\d+').firstMatch(text)?.group(0);
    if (number == null) return text;
    return '${number}y';
  }

  String _countText(Object? value) {
    final count = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return count >= 100 ? '$count+' : count.toString();
  }

  String _ratingText(Object? value) {
    final rating = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return rating.toStringAsFixed(1);
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.lg18Bold.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40.h, width: 1, color: AppColors.borderPrimary);
  }

  Widget _buildAvailabilitySection() {
    return Obx(() {
      final options = controller.availabilityOptions;
      final selectedId = controller.selectedClassId.value;

      if (controller.isLoadingClasses.value && options.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.actionPrimary),
          ),
        );
      }

      if (options.isEmpty) {
        final errorMessage = controller.classesErrorMessage.value;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            errorMessage.isNotEmpty
                ? errorMessage
                : 'No available class slots.',
            style: AppTextStyles.sm14Medium.copyWith(
              color: errorMessage.isNotEmpty
                  ? AppColors.statusError
                  : AppColors.textSecondary,
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Classes",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(
                    () => _AllAvailabilityClassesScreen(controller: controller),
                  ),
                  child: Text(
                    "See all",
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.actionPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: options.map((option) {
                  final classId = option['classId']?.toString() ?? '';
                  final isSelected = selectedId == classId;

                  return SizedBox(
                    width: 398.w,
                    child: _AvailabilityClassCard(
                      option: option,
                      selected: isSelected,
                      margin: EdgeInsets.only(right: 12.w),
                      onTap: () => controller.selectClass(classId),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildReviewsSection() {
    return Obx(() {
      final reviews = controller.reviews;
      final errorMessage = controller.reviewsErrorMessage.value;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reviews",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.trainerReviewsScreen,
                    arguments: {'reviews': reviews.toList()},
                  ),
                  child: Text(
                    "See all",
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.actionPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (controller.isLoadingReviews.value && reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 22.h),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.actionPrimary,
                ),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errorMessage.isNotEmpty ? errorMessage : 'No reviews yet.',
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: errorMessage.isNotEmpty
                        ? AppColors.statusError
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 210.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final image = review["image"] ?? '';
                  return Container(
                    width: 320.w,
                    margin: EdgeInsets.only(right: 12.w),
                    child: ReviewCard(
                      name: review["name"] ?? 'Member',
                      rating: review["rating"] ?? '0.0',
                      timeAgo: review["time"] ?? '',
                      reviewText: review["text"] ?? '',
                      imageUrl: image.isEmpty
                          ? "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop"
                          : image,
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBioSection() {
    return Obx(() {
      final trainer = controller.trainer.value ?? const <String, dynamic>{};
      final bio = trainer['bio']?.toString();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal Bio",
              style: AppTextStyles.base16Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              bio != null && bio.isNotEmpty
                  ? bio
                  : "No personal bio added yet.",
              style: AppTextStyles.sm14Regular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLocationSection() {
    return Obx(() {
      final trainer = controller.trainer.value ?? const <String, dynamic>{};

      // Extract raw values — they may be null, NaN, or Infinity if the trainer
      // has no location set or the backend serialised a NaN coordinate.
      final rawLat = trainer['lat'] is num
          ? (trainer['lat'] as num).toDouble()
          : null;
      final rawLng = trainer['lng'] is num
          ? (trainer['lng'] as num).toDouble()
          : null;

      // Guard: LatLng throws if either coordinate is not finite (NaN / ±Infinity).
      final hasLocation =
          rawLat != null &&
          rawLat.isFinite &&
          rawLng != null &&
          rawLng.isFinite;

      final locationLabel = trainer['locationLabel']?.toString() ?? '';

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Location",
              style: AppTextStyles.base16Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (locationLabel.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                locationLabel,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            if (!hasLocation)
              Container(
                height: 200.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 36.sp,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Location not available',
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(rawLat!, rawLng!),
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.sparktech.herfitness',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(rawLat, rawLng),
                            width: 40.w,
                            height: 40.w,
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.actionPrimary,
                              size: 40.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Get.toNamed(
            AppRoutes.bookTrainerScreen,
            arguments: controller.bookingArguments,
          ),
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Book now",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.calendar_month, color: Colors.white, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllAvailabilityClassesScreen extends StatelessWidget {
  final TrainerDetailsController controller;

  const _AllAvailabilityClassesScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const CustomAppbar(title: "Classes"),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: Obx(() {
                    final options = controller.availabilityOptions;
                    final selectedId = controller.selectedClassId.value;

                    if (options.isEmpty) {
                      final errorMessage = controller.classesErrorMessage.value;
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            errorMessage.isNotEmpty
                                ? errorMessage
                                : 'No available class slots.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.sm14Medium.copyWith(
                              color: errorMessage.isNotEmpty
                                  ? AppColors.statusError
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        bottom: 120.h,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final classId = option['classId']?.toString() ?? '';
                        final isSelected = selectedId == classId;

                        return _AvailabilityClassCard(
                          option: option,
                          selected: isSelected,
                          onTap: () => controller.selectClass(classId),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.bookTrainerScreen,
                  arguments: controller.bookingArguments,
                ),
                child: Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Book now",
                        style: AppTextStyles.base16Medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityClassCard extends StatefulWidget {
  final Map<String, Object?> option;
  final bool selected;
  final EdgeInsetsGeometry? margin;
  final VoidCallback onTap;

  const _AvailabilityClassCard({
    required this.option,
    required this.selected,
    this.margin,
    required this.onTap,
  });

  @override
  State<_AvailabilityClassCard> createState() => _AvailabilityClassCardState();
}

class _AvailabilityClassCardState extends State<_AvailabilityClassCard> {
  bool _isExpanded = false;
  bool _showAllDates = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.option['title']?.toString() ?? 'Class';
    final date = widget.option['date']?.toString() ?? '';
    final time = widget.option['time']?.toString() ?? '';
    final location =
        widget.option['location']?.toString() ?? 'Location unavailable';
    final classType = widget.option['classType']?.toString() ?? 'N/A';
    final sessionFormat =
        widget.option['sessionFormat']?.toString() ?? 'Session';
    final planType = widget.option['planType']?.toString() ?? 'Single';
    final price = widget.option['price']?.toString() ?? '0.00';
    final spots = widget.option['spotsRemaining'];
    final totalSlots = widget.option['totalSlots'] as int? ?? 1;
    final isMultiSlot = totalSlots > 1;
    final slots = widget.option['slots'] as List<Map<String, dynamic>>? ?? [];

    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (isMultiSlot) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        margin: widget.margin ?? EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: widget.selected
                ? AppColors.actionPrimary
                : AppColors.borderPrimary,
            width: widget.selected ? 1.4.w : 1.w,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: AppColors.actionPrimary.withValues(alpha: 0.18),
                    blurRadius: 0,
                    spreadRadius: 3.w,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm14SemiBold.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isFewSpots =
                        !isMultiSlot && spots is int && spots > 0 && spots <= 3;

                    final text = isMultiSlot
                        ? '$totalSlots slots available'
                        : (spots is int && spots > 0
                              ? (isFewSpots
                                    ? 'Only $spots left'
                                    : '$spots spots left')
                              : '');

                    if (text.isEmpty) return const SizedBox.shrink();

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? AppColors.actionPrimary.withValues(alpha: 0.1)
                            : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMultiSlot
                                ? (_isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded)
                                : (isFewSpots
                                      ? Icons.whatshot_rounded
                                      : Icons.people_outline),
                            size: 16.sp,
                            color: widget.selected
                                ? AppColors.actionPrimary
                                : (isFewSpots
                                      ? Colors.orange
                                      : AppColors.textSecondary),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            text,
                            style: AppTextStyles.xs12Medium.copyWith(
                              color: widget.selected
                                  ? AppColors.actionPrimary
                                  : (isFewSpots
                                        ? Colors.orange
                                        : AppColors.textSecondary),
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 18.w,
              runSpacing: 10.h,
              children: [
                _meta(Icons.calendar_month_outlined, date),
                _meta(Icons.schedule_rounded, time),
                _meta(Icons.location_on_outlined, location),
              ],
            ),
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  _info('Delivery', _formatDeliveryType(classType)),
                  _info('Format', _formatSessionFormat(sessionFormat)),
                  _info('Session', _formatPlanType(planType)),
                  _info('Per Member', _priceText(price)),
                ],
              ),
            ),
            if (_isExpanded && isMultiSlot) ...[
              SizedBox(height: 16.h),
              Divider(color: AppColors.borderPrimary, height: 1),
              SizedBox(height: 12.h),
              Text(
                'Available Times',
                style: AppTextStyles.xs12SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Builder(
                builder: (context) {
                  final grouped = _groupSlotsByDate(slots);
                  final showSeeMore = grouped.length > 3;
                  final displayedGroups = _showAllDates
                      ? grouped
                      : grouped.take(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...displayedGroups.map((group) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.actionPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  group['date']!,
                                  style: AppTextStyles.xs12SemiBold.copyWith(
                                    color: AppColors.actionPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    "${group['range']} available",
                                    style: AppTextStyles.xs12Medium.copyWith(
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (showSeeMore)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showAllDates = !_showAllDates),
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Row(
                              children: [
                                Text(
                                  _showAllDates
                                      ? "Show less"
                                      : "See ${grouped.length - 3} more dates",
                                  style: AppTextStyles.xs12SemiBold.copyWith(
                                    color: AppColors.actionPrimary,
                                  ),
                                ),
                                Icon(
                                  _showAllDates
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16.sp,
                                  color: AppColors.actionPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupSlotsByDate(
    List<Map<String, dynamic>> slots,
  ) {
    final Map<String, List<String>> grouped = {};

    for (var slot in slots) {
      final date = slot['date']?.toString() ?? 'N/A';
      final time = slot['time']?.toString() ?? '';
      if (time.isNotEmpty) {
        grouped.putIfAbsent(date, () => []).add(time);
      }
    }

    return grouped.entries.map((e) {
      final times = e.value;
      String rangeText = "";
      if (times.isNotEmpty) {
        // Assuming times are sequential, take first start and last end
        final firstStart = times.first.split('-').first.trim();
        final lastEnd = times.last.split('-').last.trim();
        rangeText = "$firstStart - $lastEnd";
      }
      return {'date': e.key, 'times': times, 'range': rangeText};
    }).toList();
  }

  String _formatDeliveryType(String type) {
    if (type.toUpperCase() == 'IN_PERSON') return 'Offline';
    if (type.toUpperCase() == 'ONLINE') return 'Online';
    return type;
  }

  String _formatSessionFormat(String format) {
    if (format.toUpperCase() == 'PRIVATE') return 'Private';
    if (format.toUpperCase() == 'GROUP') return 'Group';
    return format;
  }

  String _formatPlanType(String planType) {
    if (planType == 'SINGLE_SESSION') return 'Single';
    if (planType == 'MONTHLY_SESSION') return 'Monthly';
    if (planType == 'MONTHLY') return 'Monthly';
    if (planType.toLowerCase().contains('single')) return 'Single';
    if (planType.toLowerCase().contains('month')) return 'Monthly';
    return planType;
  }

  Widget _meta(IconData icon, String text) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 180.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: AppColors.iconSecondary),
          SizedBox(width: 7.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.xs12Medium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.xxs9Regular.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.xxs9SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _priceText(String value) {
    final text = value.trim();
    if (text.isEmpty) return r'$0.00';
    if (text.startsWith(r'$')) return text;
    return '\$$text';
  }
}
