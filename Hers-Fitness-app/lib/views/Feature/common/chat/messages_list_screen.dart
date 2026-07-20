import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../Helpers/route.dart';
import '../../../../utils/AppColor/app_colors.dart';
import '../../../../utils/AppTextStyle/app_text_styles.dart';
import '../../../Base/CustomAppbar/custom_appbar.dart';
import '../../../Base/CustomTextfield/CustomTextfield.dart';
import '../../../../controllers/common/chat_controller.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Prevents a rapid double-tap from pushing two ChatScreen instances onto the
  // navigation stack.  Two screens sharing the singleton ChatController would
  // each call openConversation — the second call clears the already-loaded
  // messages and triggers the "No messages yet." flash.
  bool _isNavigating = false;

  Future<void> _goHome() async {
    final role = (await TokenStorage().getUserRole())?.toLowerCase();
    if (role == 'trainer') {
      Get.offAllNamed(AppRoutes.trainerBottomNavScreen);
    } else {
      Get.offAllNamed(AppRoutes.memberBottomNavScreen);
    }
  }

  void _openChat(ChatContact contact) {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    Get.to(() => ChatScreen(contact: contact))?.whenComplete(() {
      if (mounted) setState(() => _isNavigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      title: "Messages",
                      showBack: false,
                      onTap: _goHome,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: CustomTextField(
                      controller: controller.searchController,
                      hintText: "Search Messages...",
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppColors.textPrimary,
                        size: 24.sp,
                      ),
                      filColor: Colors.white,
                      borderColor: AppColors.borderSecondary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: Obx(() {
                      final contacts = controller.filteredContacts;
                      if (controller.isLoadingConversations.value &&
                          contacts.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.actionPrimary,
                          ),
                        );
                      }

                      if (contacts.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () =>
                              controller.fetchConversations(showError: true),
                          child: ListView(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            children: [
                              SizedBox(height: 120.h),
                              Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  color: AppColors.bgTertiary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.textTertiary,
                                  size: 36.sp,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                'No conversations yet.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.base16Medium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Your messages with trainers and members will appear here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.sm14Regular.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            controller.fetchConversations(showError: true),
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            top: 8.h,
                            left: 20.w,
                            right: 20.w,
                            bottom: 40.h,
                          ),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return Dismissible(
                              key: Key(contact.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) =>
                                  controller.contacts.removeAt(index),
                              background: Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.only(right: 20.w),
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: AppColors.statusError,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 28.sp,
                                ),
                              ),
                              child: _buildContactItem(contact, controller),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildContactItem(ChatContact contact, ChatController controller) {
    return GestureDetector(
      onTap: () => _openChat(contact),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildAvatar(contact.avatarUrl, 50.w, contact.isParticipantActive),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.base16Medium.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatContactTime(contact.updatedAt),
                        style: AppTextStyles.xxs9Regular.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (contact.isParticipantActive) ...[
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Expanded(
                        child: Text(
                          contact.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sm14Regular.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (contact.unreadCount > 0) ...[
              SizedBox(width: 10.w),
              Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: AppColors.actionPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.unreadCount.toString(),
                    style: AppTextStyles.sm14Regular.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, double size, bool isActive) {
    final avatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(size),
            ),
          )
        : _avatarFallback(size);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isActive)
          Positioned(
            right: -1.w,
            bottom: -1.w,
            child: Container(
              width: 13.w,
              height: 13.w,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.w),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(Icons.person, color: Colors.grey[600]),
    );
  }
}

String _formatContactTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  return '${local.month}/${local.day}/${local.year.toString().substring(2)}';
}
