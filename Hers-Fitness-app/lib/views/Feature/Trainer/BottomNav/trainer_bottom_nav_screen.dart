import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utils/AppColor/app_colors.dart';
import '../Home/trainer_home_screen.dart';
import '../Schedule/schedule_screen.dart';
import '../Classes/my_classes_screen.dart';
import '../Profile/trainer_profile_screen.dart';
import '../../common/chat/messages_list_screen.dart';

class TrainerBottomNavScreen extends StatefulWidget {
  final int initialIndex;
  const TrainerBottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<TrainerBottomNavScreen> createState() => _TrainerBottomNavScreenState();
}

class CustomNotchedRectangle extends NotchedShape {
  final double margin;
  const CustomNotchedRectangle(this.margin);

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest != null) {
      guest = guest.shift(Offset(-margin, 0));
    }
    return const CircularNotchedRectangle().getOuterPath(host, guest);
  }
}

class _TrainerBottomNavScreenState extends State<TrainerBottomNavScreen> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // Finalized pages for navigation
  final List<Widget> _pages = [
    const TrainerHomeScreen(),
    MyClassesScreen(),
    const ScheduleScreen(),
    const MessagesListScreen(),
    const TrainerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Allow the system to pop only when we're already on the Home tab.
      // On any other tab the back gesture is intercepted and we go to Home.
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        extendBody: false,
        body: _pages[selectedIndex],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          width: 66.w,
          height: 66.w,
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: AppColors.actionPrimary,
            shape: const CircleBorder(),
            onPressed: () => _onItemTapped(2),
            child: Icon(
              Icons.event_available,
              color: Colors.white,
              size: 38.sp,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.19),
                  blurRadius: 50,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BottomAppBar(
                elevation: 0,
                color: Colors.white,
                padding: EdgeInsets.zero,
                shape: CustomNotchedRectangle(16.w),
                notchMargin: 10,
                child: SizedBox(
                  height: 75.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(icon: Icons.home_filled, index: 0),
                      _buildNavItem(
                        icon: Icons.fitness_center_rounded,
                        index: 1,
                      ),
                      SizedBox(width: 48.w),
                      _buildNavItem(icon: Icons.chat_bubble_rounded, index: 3),
                      _buildNavItem(icon: Icons.person_rounded, index: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.actionPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected
                      ? AppColors.actionPrimary
                      : Colors.grey.shade500,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 24.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.actionPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
