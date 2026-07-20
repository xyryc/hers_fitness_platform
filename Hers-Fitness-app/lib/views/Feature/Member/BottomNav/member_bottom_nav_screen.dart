import 'package:fitness/views/Feature/Member/Trainer/trainer_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness/controllers/member/member_home_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness/views/Feature/Member/Home/member_home_screen.dart';
import 'package:fitness/views/Feature/Member/MyClasses/my_classes_screen.dart';
import 'package:fitness/views/Feature/common/chat/messages_list_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/AppColor/app_colors.dart';
import '../Profile/member_profile_screen.dart';

class MemberBottomNavScreen extends StatefulWidget {
  final int initialIndex;
  const MemberBottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MemberBottomNavScreen> createState() => _MemberBottomNavScreenState();
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

class _MemberBottomNavScreenState extends State<MemberBottomNavScreen> {
  late int selectedIndex;

  // SVG Icon Strings
  static const String _homeSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20.83 8.01L14.28 2.77C13 1.75 11 1.74 9.72999 2.76L3.17999 8.01C2.23999 8.76 1.66999 10.26 1.86999 11.44L3.12999 18.98C3.41999 20.67 4.98999 22 6.69999 22H17.3C18.99 22 20.59 20.64 20.88 18.97L22.14 11.43C22.32 10.26 21.75 8.76 20.83 8.01ZM12.75 18C12.75 18.41 12.41 18.75 12 18.75C11.59 18.75 11.25 18.41 11.25 18V15C11.25 14.59 11.59 14.25 12 14.25C12.41 14.25 12.75 14.59 12.75 15V18Z" fill="currentColor"/></svg>''';
  static const String _trainerSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M4.61045 16.7929C5.00097 17.1834 5.00097 17.8166 4.61045 18.2071L3.74489 19.0727C3.41837 19.3992 3.41837 19.9286 3.74489 20.2551C4.07142 20.5816 4.60082 20.5816 4.92734 20.2551L5.79289 19.3896C6.18342 18.999 6.81658 18.999 7.20711 19.3896C7.59763 19.7801 7.59763 20.4132 7.20711 20.8038L6.34155 21.6693C5.23398 22.7769 3.43825 22.7769 2.33068 21.6693C1.22311 20.5617 1.22311 18.766 2.33068 17.6584L3.19623 16.7929C3.58676 16.4024 4.21992 16.4024 4.61045 16.7929Z" fill="currentColor"/><path fill-rule="evenodd" clip-rule="evenodd" d="M20.2551 3.74489C19.9286 3.41837 19.3992 3.41837 19.0727 3.74489L18.2071 4.61045C17.8166 5.00097 17.1834 5.00097 16.7929 4.61045C16.4024 4.21992 16.4024 3.58676 16.7929 3.19623L17.6584 2.33068C18.766 1.22311 20.5617 1.22311 21.6693 2.33068C22.7769 3.43825 22.7769 5.23398 21.6693 6.34155L20.8038 7.20711C20.4132 7.59763 19.7801 7.59763 19.3896 7.20711C18.999 6.81658 18.999 6.18342 19.3896 5.79289L20.2551 4.92734C20.5816 4.60082 20.5816 4.07142 20.2551 3.74489Z" fill="currentColor"/><path d="M19.8371 11.8024C19.5136 12.0492 19.1356 12.25 18.6623 12.25C18.1889 12.25 17.811 12.0492 17.4875 11.8024C17.1903 11.5757 16.8661 11.2514 16.5027 10.888L13.1121 7.4973C12.7486 7.13391 12.4243 6.80971 12.1976 6.51251C11.9508 6.18904 11.75 5.81106 11.75 5.33771C11.75 4.86435 11.9508 4.48638 12.1976 4.1629C12.4243 3.86571 12.8147 3.47543 13.1781 3.11205C13.5415 2.7486 13.8657 2.42434 14.1629 2.19759C14.4864 1.95078 14.8644 1.75 15.3377 1.75C15.8111 1.75 16.189 1.95078 16.5125 2.19759C16.8097 2.42434 17.1339 2.74859 17.4973 3.11204L20.8879 6.5027L20.888 6.50271C21.2514 6.8661 21.5757 7.1903 21.8024 7.48749C22.0492 7.81096 22.25 8.18894 22.25 8.66229C22.25 9.13565 22.0492 9.51362 21.8024 9.8371C21.5757 10.1343 21.2514 10.4585 20.888 10.8219C20.5246 11.1853 20.1343 11.5757 19.8371 11.8024Z" fill="currentColor"/><path d="M9.8371 21.8024C9.51362 22.0492 9.13565 22.25 8.66229 22.25C8.18894 22.25 7.81096 22.0492 7.48749 21.8024C7.1903 21.5757 6.8661 21.2514 6.50271 20.888L3.11206 17.4973C2.7486 17.1339 2.42434 16.8097 2.19759 16.5125C1.95078 16.189 1.75 15.8111 1.75 15.3377C1.75 14.8644 1.95078 14.4864 2.19759 14.1629C2.42434 13.8657 2.81467 13.4754 3.17812 13.112C3.54151 12.7486 3.86571 12.4243 4.1629 12.1976C4.48638 11.9508 4.86435 11.75 5.33771 11.75C5.81106 11.75 6.18904 11.9508 6.51251 12.1976C6.8097 12.4243 7.1339 12.7486 7.49729 13.112L10.8879 16.5027L10.888 16.5027C11.2514 16.8661 11.5757 17.1903 11.8024 17.4875C12.0492 17.811 12.25 18.1889 12.25 18.6623C12.25 19.1356 12.0492 19.5136 11.8024 19.8371C11.5757 20.1343 11.2514 20.4585 10.888 20.8219C10.5246 21.1853 10.1343 21.5757 9.8371 21.8024Z" fill="currentColor"/><path d="M8.5262 11.8433C8.67284 11.7281 8.82056 11.6237 8.93124 11.5719C9.82663 11.1528 10.258 10.8977 10.5769 10.5788C10.8958 10.2599 11.1508 9.82859 11.5699 8.93319C11.6217 8.82252 11.7261 8.67479 11.8413 8.52815C12.0173 8.30411 12.1053 8.19208 12.24 8.18402C12.3746 8.17596 12.4808 8.28214 12.6932 8.4945L15.5058 11.3072C15.7182 11.5195 15.8244 11.6257 15.8163 11.7604C15.8083 11.895 15.6962 11.983 15.4722 12.159C15.3255 12.2742 15.1778 12.3786 15.0671 12.4304C14.1717 12.8495 13.7404 13.1046 13.4215 13.4235C13.1026 13.7424 12.8476 14.1737 12.4285 15.0691C12.3767 15.1798 12.2722 15.3275 12.1571 15.4741C11.9811 15.6982 11.8931 15.8102 11.7584 15.8183C11.6238 15.8263 11.5176 15.7202 11.3052 15.5078L8.49254 12.6951C8.28019 12.4828 8.17401 12.3766 8.18207 12.2419C8.19013 12.1073 8.30215 12.0193 8.5262 11.8433Z" fill="currentColor"/></svg>''';
  static const String _calendarOutlineSvg =
      '''<svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9.75644 2.43912V6.09778" stroke="white" stroke-width="1.82933" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.5129 2.43912V6.09778" stroke="white" stroke-width="1.82933" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M4.26844 11.0858H25.0009" stroke="white" stroke-width="1.82933" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M25.6107 10.3662V20.7324C25.6107 24.3911 23.7813 26.8302 19.5129 26.8302H9.75644C5.488 26.8302 3.65867 24.3911 3.65867 20.7324V10.3662C3.65867 6.70756 5.488 4.26845 9.75644 4.26845H19.5129C23.7813 4.26845 25.6107 6.70756 25.6107 10.3662Z" stroke="white" stroke-width="1.82933" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.1406 16.7079H19.1515" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.1406 20.3666H19.1515" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/><path d="M14.6292 16.7079H14.6401" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/><path d="M14.6292 20.3666H14.6401" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/><path d="M10.1154 16.7079H10.1263" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/><path d="M10.1154 20.3666H10.1263" stroke="white" stroke-width="2.43911" stroke-linecap="round" stroke-linejoin="round"/></svg>''';
  static const String _calendarFilledSvg =
      '''<svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20.4276 4.34162V2.43911C20.4276 1.93909 20.0129 1.52444 19.5129 1.52444C19.0129 1.52444 18.5982 1.93909 18.5982 2.43911V4.26844H10.6711V2.43911C10.6711 1.93909 10.2565 1.52444 9.75644 1.52444C9.25643 1.52444 8.84178 1.93909 8.84178 2.43911V4.34162C5.54898 4.64651 3.95136 6.60999 3.70745 9.52473C3.68306 9.8784 3.97575 10.1711 4.31723 10.1711H24.9521C25.3058 10.1711 25.5985 9.8662 25.5619 9.52473C25.318 6.60999 23.7204 4.64651 20.4276 4.34162Z" fill="white"/><path d="M24.3911 12.0004H4.87822C4.20747 12.0004 3.65867 12.5492 3.65867 13.22V20.7324C3.65867 24.3911 5.488 26.8302 9.75644 26.8302H19.5129C23.7813 26.8302 25.6107 24.3911 25.6107 20.7324V13.22C25.6107 12.5492 25.0619 12.0004 24.3911 12.0004ZM11.2321 22.2081C11.1711 22.2569 11.1102 22.3179 11.0492 22.3545C10.976 22.4032 10.9028 22.4398 10.8297 22.4642C10.7565 22.5008 10.6833 22.5252 10.6101 22.5374C10.5248 22.5496 10.4516 22.5618 10.3662 22.5618C10.2077 22.5618 10.0491 22.5252 9.90279 22.4642C9.74425 22.4032 9.62229 22.3179 9.50034 22.2081C9.28082 21.9764 9.14667 21.6593 9.14667 21.3422C9.14667 21.0251 9.28082 20.7081 9.50034 20.4763C9.62229 20.3666 9.74425 20.2812 9.90279 20.2202C10.1223 20.1227 10.3662 20.0983 10.6101 20.1471C10.6833 20.1593 10.7565 20.1836 10.8297 20.2202C10.9028 20.2446 10.976 20.2812 11.0492 20.33C11.1102 20.3788 11.1711 20.4276 11.2321 20.4763C11.4516 20.7081 11.5858 21.0251 11.5858 21.3422C11.5858 21.6593 11.4516 21.9764 11.2321 22.2081ZM11.2321 17.9397C11.0004 18.1592 10.6833 18.2933 10.3662 18.2933C10.0491 18.2933 9.73205 18.1592 9.50034 17.9397C9.28082 17.7079 9.14667 17.3909 9.14667 17.0738C9.14667 16.7567 9.28082 16.4396 9.50034 16.2079C9.84181 15.8664 10.3784 15.7567 10.8297 15.9518C10.9882 16.0128 11.1223 16.0981 11.2321 16.2079C11.4516 16.4396 11.5858 16.7567 11.5858 17.0738C11.5858 17.3909 11.4516 17.7079 11.2321 17.9397ZM15.5006 22.5618C15.4153 22.5618 15.3421 22.5496 15.2567 22.5374C15.1835 22.5252 15.1103 22.5008 15.0372 22.4642C14.964 22.4398 14.8908 22.4032 14.8177 22.3545C14.7567 22.3179 14.6957 22.2569 14.6348 22.2081C14.4152 21.9764 14.2811 21.6593 14.2811 21.3422C14.2811 21.0251 14.4152 20.7081 14.6348 20.4763C14.6957 20.4276 14.7567 20.3788 14.8177 20.33C14.8908 20.2812 14.964 20.2446 15.0372 20.2202C15.1103 20.1836 15.1835 20.1593 15.2567 20.1471C15.5006 20.0983 15.7445 20.1227 15.964 20.2202C16.1226 20.2812 16.2445 20.3666 16.3665 20.4763C16.586 20.7081 16.7202 21.0251 16.7202 21.3422C16.7202 21.6593 16.586 21.9764 16.3665 22.2081C16.2445 22.3179 16.1226 22.4032 15.964 22.4642C15.8177 22.5252 15.6591 22.5618 15.5006 22.5618ZM15.5006 18.2933C15.1835 18.2933 14.8664 18.1592 14.6348 17.9397C14.4152 17.7079 14.2811 17.3909 14.2811 17.0738C14.2811 16.7567 14.4152 16.4396 14.6348 16.2079C14.7445 16.0981 14.8787 16.0128 15.0372 15.9518C15.4885 15.7567 16.0251 15.8664 16.3665 16.2079C16.4763 16.3176 16.6105 16.4518 16.6714 16.6104C16.7324 16.769 16.7202 16.9275 16.7202 17.0861C16.7202 17.4031 16.586 17.7202 16.3665 17.9519C16.1348 18.1592 15.8177 18.2933 15.5006 18.2933ZM19.1472 21.3422C19.1472 21.6593 19.2813 21.9764 19.5009 22.2081C19.6228 22.3179 19.7448 22.4032 19.9033 22.4642C20.0497 22.5252 20.2082 22.5618 20.3668 22.5618C20.4521 22.5618 20.5253 22.5496 20.6107 22.5374C20.6838 22.5252 20.757 22.5008 20.8302 22.4642C20.9033 22.4398 20.9765 22.4032 21.0497 22.3545C21.1107 22.3179 21.1717 22.2569 21.2326 22.2081C21.4522 21.9764 21.5863 21.6593 21.5863 21.3422C21.5863 21.0251 21.4522 20.7081 21.2326 20.4763C21.1717 20.4276 21.1107 20.3788 21.0497 20.33C20.9765 20.2812 20.9033 20.2446 20.8302 20.2202C20.757 20.1836 20.6838 20.1593 20.6107 20.1471C20.3668 20.0983 20.1228 20.1227 19.9033 20.2202C19.7448 20.2812 19.6228 20.3666 19.5009 20.4763C19.2813 20.7081 19.1472 21.0251 19.1472 21.3422ZM20.3668 18.2933C20.0497 18.2933 19.7326 18.1592 19.5009 17.9397C19.2813 17.7079 19.1472 17.3909 19.1472 17.0738C19.1472 16.7567 19.2813 16.4396 19.5009 16.2079C19.6106 16.0981 19.7448 16.0128 19.9033 15.9518C20.3545 15.7567 20.8911 15.8664 21.2326 16.2079C21.3424 16.3176 21.4765 16.4518 21.5375 16.6104C21.5985 16.769 21.5863 16.9275 21.5863 17.0861C21.5863 17.4031 21.4522 17.7202 21.2326 17.9519C21.0009 18.1592 20.6838 18.2933 20.3668 18.2933Z" fill="white"/></svg>''';
  static const String _chatSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M16 2H8C4 2 2 4 2 8V21C2 21.55 2.45 22 3 22H16C20 22 22 20 22 16V8C22 4 20 2 16 2ZM14 15.25H7C6.59 15.25 6.25 14.91 6.25 14.5C6.25 14.09 6.59 13.75 7 13.75H14C14.41 13.75 14.75 14.09 14.75 14.5C14.75 14.91 14.41 15.25 14 15.25ZM17 10.25H7C6.59 10.25 6.25 9.91 6.25 9.5C6.25 9.09 6.59 8.75 7 8.75H17C17.41 8.75 17.75 14.09 17.75 9.5C17.75 9.91 17.41 10.25 17 10.25Z" fill="currentColor"/></svg>''';
  static const String _profileSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C9.38 2 7.25 4.13 7.25 6.75C7.25 9.32 9.26 11.4 11.88 11.49C11.96 11.48 12.04 11.48 12.1 11.49C12.12 11.49 12.13 11.49 12.15 11.49C12.16 11.49 12.16 11.49 12.17 11.49C14.73 11.4 16.74 9.32 16.75 6.75C16.75 4.13 14.62 2 12 2Z" fill="currentColor"/><path d="M17.08 14.15C14.29 12.29 9.74001 12.29 6.93001 14.15C5.66001 15 4.96001 16.15 4.96001 17.38C4.96001 18.61 5.66001 19.75 6.92001 20.59C8.32001 21.53 10.16 22 12 22C13.84 22 15.68 21.53 17.08 20.59C18.34 19.74 19.04 18.6 19.04 17.36C19.03 16.13 18.34 14.99 17.08 14.15Z" fill="currentColor"/></svg>''';

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (index == 0 && selectedIndex != 0) {
      if (Get.isRegistered<MemberHomeController>()) {
        Get.find<MemberHomeController>().updateWorkoutImage();
      }
    }
    setState(() {
      selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    MemberHomeScreen(),
    TrainerListScreen(),
    MemberMyClassesScreen(),
    const MessagesListScreen(),
    const MemberProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: SvgPicture.string(
            selectedIndex == 2 ? _calendarFilledSvg : _calendarOutlineSvg,
            width: 38.w,
            height: 38.w,
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
                    _buildNavItem(svgString: _homeSvg, index: 0),
                    _buildNavItem(svgString: _trainerSvg, index: 1),
                    SizedBox(width: 48.w),
                    _buildNavItem(svgString: _chatSvg, index: 3),
                    _buildNavItem(svgString: _profileSvg, index: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required String svgString, required int index}) {
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
                SvgPicture.string(
                  svgString,
                  width: 24.w,
                  height: 24.w,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? AppColors.actionPrimary
                        : const Color(0xFF7A7A7A),
                    BlendMode.srcIn,
                  ),
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
