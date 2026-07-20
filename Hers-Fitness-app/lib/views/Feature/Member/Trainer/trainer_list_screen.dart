import 'package:fitness/controllers/member/trainer_bookmark_controller.dart';
import 'package:fitness/controllers/member/trainer_list_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:fitness/views/Feature/Member/Home/widgets/trainer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../Helpers/route.dart';

class TrainerListScreen extends StatelessWidget {
  TrainerListScreen({super.key});

  final TrainerListController controller =
      Get.isRegistered<TrainerListController>()
      ? Get.find<TrainerListController>()
      : Get.put(TrainerListController());
  final TrainerBookmarkController bookmarkController =
      Get.isRegistered<TrainerBookmarkController>()
      ? Get.find<TrainerBookmarkController>()
      : Get.put(TrainerBookmarkController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _buildTopGradient(context),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomAppbar(
                    title: "Trainer",
                    showBack: false,
                    onTap: () =>
                        Get.offAllNamed(AppRoutes.memberBottomNavScreen),
                    trailing: _buildHeaderBookmarkButton(),
                  ),
                ),
                SizedBox(height: 24.h),
                Obx(
                  () => Expanded(
                    child: controller.showBookmarkedOnly.value
                        ? _buildBookmarkedSection()
                        : Column(
                            children: [
                              _buildTabs(),
                              SizedBox(height: 16.h),
                              Expanded(
                                child: Obx(() {
                                  if (controller.selectedTab.value ==
                                      "Search") {
                                    return _buildSearchSection();
                                  } else {
                                    return _buildNearYouSection();
                                  }
                                }),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top + 250.h,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFDADF).withValues(alpha: 0.9),
                    const Color(0xFFFFECEE).withValues(alpha: 0.8),
                    const Color(0xFFFFF7F5).withValues(alpha: 0.58),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.46, 0.78, 1],
                ),
              ),
            ),
            Positioned(
              left: -78.w,
              top: -38.h,
              width: 220.w,
              height: 220.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFBECB).withValues(alpha: 0.5),
                      const Color(0xFFFFDDE4).withValues(alpha: 0.26),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -76.w,
              top: -26.h,
              width: 230.w,
              height: 230.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFC1CF).withValues(alpha: 0.45),
                      const Color(0xFFFFE1E7).withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBookmarkButton() {
    return Obx(() {
      final isActive =
          controller.showBookmarkedOnly.value ||
          bookmarkController.bookmarkedTrainers.isNotEmpty;

      return GestureDetector(
        onTap: controller.toggleBookmarkedOnly,
        child: SvgPicture.asset(
          isActive
              ? "assets/icons/befor_bookmark.svg"
              : "assets/icons/after_bookmark.svg",
          width: 52.w,
          height: 52.w,
        ),
      );
    });
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF2F2F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Obx(() {
            bool isNearYou = controller.selectedTab.value == "Near You";
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isNearYou
                  ? 0
                  : (MediaQuery.of(Get.context!).size.width - 52.w) / 2,
              right: isNearYou
                  ? (MediaQuery.of(Get.context!).size.width - 52.w) / 2
                  : 0,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.actionPrimary,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            );
          }),
          Row(children: [_buildTabItem("Near You"), _buildTabItem("Search")]),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTab(title),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Center(
            child: Obx(() {
              bool isSelected = controller.selectedTab.value == title;
              return Text(
                title,
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkedSection() {
    return Obx(() {
      final trainers = bookmarkController.savedTrainers;

      if (trainers.isEmpty) {
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 80.h),
          children: [
            Center(
              child: SvgPicture.asset(
                "assets/icons/after_bookmark.svg",
                width: 52.w,
                height: 52.w,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "No bookmarked trainers yet.",
              textAlign: TextAlign.center,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bookmarked Coaches",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "${trainers.length} saved",
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              itemCount: trainers.length,
              itemBuilder: (context, index) =>
                  _buildTrainerCard(trainers[index]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNearYouSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Coaches",
                style: AppTextStyles.base16Medium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    "Most Popular",
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SvgPicture.asset("assets/icons/radar.svg"),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingNearby.value &&
                controller.nearbyTrainers.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.actionPrimary,
                ),
              );
            }

            if (controller.nearbyTrainers.isEmpty) {
              return RefreshIndicator(
                color: AppColors.actionPrimary,
                onRefresh: () =>
                    controller.fetchNearbyTrainers(showError: true),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 80.h,
                  ),
                  children: [
                    Center(
                      child: Text(
                        "No nearby trainers found.",
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.actionPrimary,
              onRefresh: () => controller.fetchNearbyTrainers(showError: true),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                itemCount: controller.nearbyTrainers.length,
                itemBuilder: (context, index) {
                  return _buildTrainerCard(controller.nearbyTrainers[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: CustomTextField(
            onChanged: controller.onSearch,
            hintText: "Search here",
            controller: searchController,
            suffixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  "${controller.searchResults.length} Result Found.",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    "Most Popular",
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SvgPicture.asset("assets/icons/radar.svg"),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingSearch.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.actionPrimary,
                ),
              );
            }

            if (controller.searchQuery.value.trim().isEmpty) {
              return Center(
                child: Text(
                  "Search trainers by name.",
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            if (controller.searchResults.isEmpty) {
              return Center(
                child: Text(
                  "No trainers found.",
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                return _buildTrainerCard(controller.searchResults[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTrainerCard(Map<String, dynamic> trainer) {
    final imageUrl = trainer['imageUrl']?.toString();

    return TrainerCard(
      name: trainer['name']?.toString() ?? 'Trainer',
      expertise: trainer['expertise']?.toString() ?? 'Fitness Trainer',
      rating: trainer['rating'] is num
          ? (trainer['rating'] as num).toDouble()
          : 0,
      price: trainer['price']?.toString() ?? 'Price unavailable',
      imageUrl: imageUrl != null && imageUrl.isNotEmpty
          ? imageUrl
          : "https://as1.ftcdn.net/jpg/02/26/49/16/1000_F_226491635_4Qp2RzkMlglsfSLIzXjLeRmqdTnaD4p8.jpg",
      distance: trainer['distance']?.toString().isNotEmpty == true
          ? trainer['distance'].toString()
          : null,
      reviewCount: trainer['reviewCount'] is num
          ? (trainer['reviewCount'] as num).toInt()
          : null,
      onTap: () {
        Get.toNamed(
          AppRoutes.trainerDetailsScreen,
          arguments: controller.trainerArgs(trainer),
        );
      },
    );
  }
}
