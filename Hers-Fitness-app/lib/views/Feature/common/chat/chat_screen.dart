import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness/controllers/common/chat_controller.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final ChatContact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;
  late final Worker _messagesWorker;
  final ScrollController _scrollController = ScrollController();

  // True until the first batch of messages has been scrolled into view.
  // The scroll guard (distanceFromBottom > threshold) is intentionally
  // skipped on the very first load so the list always opens at the bottom.
  bool _isInitialScroll = true;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openConversation(widget.contact);
    });
    _messagesWorker = ever<List<ChatMessage>>(
      controller.messages,
      (_) => _scrollToBottomIfNeeded(),
    );
  }

  @override
  void dispose() {
    _messagesWorker.dispose();
    _scrollController.dispose();
    controller.closeActiveConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildTopGradient(context),
          Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody()),
              _buildMessageInput(),
            ],
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
      height: MediaQuery.of(context).padding.top + 180.h,
      child: IgnorePointer(
        child: DecoratedBox(
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: 60.h,
        bottom: 16.h,
        left: 20.w,
        right: 20.w,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20.sp,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Obx(() {
            final selected = controller.selectedContact.value ?? widget.contact;
            return _buildAvatar(
              selected.avatarUrl,
              42.w,
              selected.isParticipantActive,
            );
          }),
          SizedBox(width: 12.w),
          Expanded(
            child: Obx(() {
              final selected =
                  controller.selectedContact.value ?? widget.contact;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base16Medium.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    controller.isParticipantTyping.value
                        ? 'Typing...'
                        : selected.isParticipantActive
                        ? 'Active now'
                        : 'Offline',
                    style: AppTextStyles.xs12Regular.copyWith(
                      color:
                          selected.isParticipantActive ||
                              controller.isParticipantTyping.value
                          ? Colors.green
                          : AppColors.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoadingMessages.value && controller.messages.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.actionPrimary),
        );
      }

      if (controller.messagesError.value.isNotEmpty &&
          controller.messages.isEmpty) {
        return _ErrorState(
          message: controller.messagesError.value,
          onRetry: () =>
              controller.fetchMessages(widget.contact.id, showError: true),
        );
      }

      if (controller.messages.isEmpty) {
        return Center(
          child: Text(
            'No messages yet.',
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        itemCount:
            controller.messages.length +
            (controller.isParticipantTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          final isTyping = controller.isParticipantTyping.value;
          if (isTyping && index == 0) {
            return _TypingIndicator(avatarUrl: widget.contact.avatarUrl);
          }

          final msgIndex =
              controller.messages.length - 1 - (isTyping ? index - 1 : index);
          final message = controller.messages[msgIndex];

          // ── Grouping Logic ──────────────────────────────────────────
          final showDayDivider =
              msgIndex == 0 ||
              !_isSameDay(
                message.createdAt,
                controller.messages[msgIndex - 1].createdAt,
              );

          final isSameSenderAsPrevious =
              msgIndex > 0 &&
              !showDayDivider &&
              controller.messages[msgIndex - 1].senderUserId ==
                  message.senderUserId;

          return Column(
            children: [
              if (showDayDivider)
                _buildTimeDivider(_formatDayLabel(message.createdAt)),
              _ChatBubble(
                key: ValueKey(message.id),
                message: message,
                isFirstInGroup: !isSameSenderAsPrevious,
                contact: widget.contact,
                onProfileTap: () => _onProfileTap(message),
                onImageTap: (url) => _openImagePreview(url),
              ),
            ],
          );
        },
      );
    });
  }

  /// Returns true when [a] and [b] fall on the same calendar day.
  /// Treats null dates as "epoch" so they never match a real message date.
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Converts a message date into a human-readable day label:
  ///   Today · Yesterday · Monday … Sunday · Jan 5, 2024
  String _formatDayLabel(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[local.weekday - 1];
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final year = local.year != now.year ? ', ${local.year}' : '';
    return '$month ${local.day}$year';
  }

  Widget _buildTimeDivider(String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.borderPrimary)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              time,
              style: AppTextStyles.xs12Regular.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.borderPrimary)),
        ],
      ),
    );
  }

  void _openImagePreview(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Hero(
              tag: imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  void _onProfileTap(ChatMessage message) {
    if (message.isMe) {
      final isTrainer =
          Get.find<ChatController>().currentUserProfile.value?.role
              ?.toLowerCase() ==
          'trainer';
      if (isTrainer) {
        Get.toNamed(AppRoutes.trainerProfileScreen);
      } else {
        Get.toNamed(AppRoutes.memberProfileScreen);
      }
    } else {
      final contact = widget.contact;
      // Use trainerUserId if available, otherwise assume it might be a member
      if (contact.trainerUserId != null && contact.trainerUserId!.isNotEmpty) {
        Get.toNamed(
          AppRoutes.trainerDetailsScreen,
          arguments: {'trainerId': contact.trainerUserId},
        );
      } else if (contact.memberUserId != null &&
          contact.memberUserId!.isNotEmpty) {
        Get.toNamed(
          AppRoutes.memberProfileScreen,
          arguments: {'memberId': contact.memberUserId},
        );
      }
    }
  }

  Widget _buildMessageInput() {
    final controller = Get.find<ChatController>();
    return Container(
      padding: EdgeInsets.only(
        top: 14.h,
        bottom: MediaQuery.of(context).padding.bottom + 14.h,
        left: 20.w,
        right: 20.w,
      ),
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
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final enabled = controller.canPickImage;
              return CustomTextField(
                controller: controller.messageController,
                hintText: 'Type a message...',
                filColor: Colors.white,
                borderColor: const Color(0xFFEBEBEB),
                borderRadius: 20.r,
                maxLines: 1,
                onSubmitted: (_) => controller.sendMessage(),
                suffixIcon: GestureDetector(
                  onTap: enabled ? _showImageSourceSheet : null,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    child: controller.isSendingImage.value
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: CircularProgressIndicator(
                              color: AppColors.actionPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.textTertiary,
                            size: 24.sp,
                          ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(width: 12.w),
          Obx(() {
            final enabled = controller.canSend;
            return GestureDetector(
              onTap: enabled ? () => controller.sendMessage() : null,
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: controller.isSending.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Transform.rotate(
                          angle: -0.5,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    final controller = Get.find<ChatController>();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          18.h,
          20.w,
          MediaQuery.of(context).padding.bottom + 18.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ImageSourceButton(
                icon: Icons.photo_camera_outlined,
                label: 'Camera',
                onTap: () {
                  Get.back();
                  controller.pickAndSendImage(ImageSource.camera);
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ImageSourceButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () {
                  Get.back();
                  controller.pickAndSendImage(ImageSource.gallery);
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAvatar(String? avatarUrl, double size, bool isActive) {
    final avatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => _avatarFallback(size),
              errorWidget: (context, url, error) => _avatarFallback(size),
            ),
          )
        : _avatarFallback(size);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11.w,
              height: 11.w,
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
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: Colors.grey[600], size: 20.sp),
    );
  }

  void _scrollToBottomIfNeeded() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final controller = Get.find<ChatController>();
      if (controller.messages.isEmpty) return;

      final position = _scrollController.position;
      // In a reversed list, 0.0 is the absolute bottom.
      final distanceFromBottom = position.pixels;

      if (_isInitialScroll) {
        _isInitialScroll = false;
        if (position.pixels != 0.0) {
          _scrollController.jumpTo(0.0);
        }
        return;
      }

      if (distanceFromBottom > 180 && controller.messages.length > 1) return;

      if (position.pixels > 0.0) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final ChatContact contact;
  final VoidCallback onProfileTap;
  final Function(String) onImageTap;

  const _ChatBubble({
    super.key,
    required this.message,
    required this.isFirstInGroup,
    required this.contact,
    required this.onProfileTap,
    required this.onImageTap,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isMe = widget.message.isMe;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isFirstInGroup ? 14.h : 4.h),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe && widget.isFirstInGroup)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h, left: 46.w),
              child: GestureDetector(
                onTap: widget.onProfileTap,
                child: Text(
                  widget.message.senderName ?? widget.contact.name,
                  style: AppTextStyles.xxs9Bold.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (widget.isFirstInGroup)
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: _buildAvatar(
                      widget.message.senderAvatarUrl ??
                          widget.contact.avatarUrl,
                      32.w,
                    ),
                  )
                else
                  SizedBox(width: 32.w),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap:
                          widget.message.messageType == 'IMAGE' &&
                              widget.message.attachmentUrl != null
                          ? () =>
                                widget.onImageTap(widget.message.attachmentUrl!)
                          : null,
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                            bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                          ),
                        ),
                        child:
                            widget.message.messageType == 'IMAGE' &&
                                widget.message.attachmentUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Hero(
                                  tag: widget.message.attachmentUrl!,
                                  child: _buildMessageImage(
                                    widget.message.attachmentUrl!,
                                  ),
                                ),
                              )
                            : Text(
                                widget.message.text,
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: isMe
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  letterSpacing: 0,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2.h,
                        right: isMe ? 4.w : 0,
                        left: isMe ? 0 : 4.w,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message.time,
                            style: AppTextStyles.xxs9Regular.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 0,
                            ),
                          ),
                          if (isMe) ...[
                            SizedBox(width: 4.w),
                            _buildStatusIcon(widget.message),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isMe) SizedBox(width: 4.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageImage(String imageUrl) {
    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (!isRemote) {
      return Image.file(File(imageUrl), width: 190.w, fit: BoxFit.cover);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 190.w,
      // Fixed height removed to allow original aspect ratios
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: 190.w,
        height: 140.h,
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.actionPrimary,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 190.w,
        height: 140.h,
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textTertiary,
            size: 32.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ChatMessage message) {
    if (message.isFailed) {
      return Icon(
        Icons.error_outline,
        color: AppColors.statusError,
        size: 12.sp,
      );
    }
    if (message.isPending) {
      return SizedBox(
        width: 10.w,
        height: 10.w,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.textTertiary,
        ),
      );
    }
    if (message.seenAt != null) {
      return Stack(
        children: [
          Icon(Icons.check, color: AppColors.actionPrimary, size: 12.sp),
          Positioned(
            left: 3.w,
            child: Icon(
              Icons.check,
              color: AppColors.actionPrimary,
              size: 12.sp,
            ),
          ),
        ],
      );
    }
    return Icon(Icons.check, color: AppColors.textTertiary, size: 12.sp);
  }

  Widget _buildAvatar(String? avatarUrl, double size) {
    final avatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => _avatarFallback(size),
              errorWidget: (context, url, error) => _avatarFallback(size),
            ),
          )
        : _avatarFallback(size);

    return avatar;
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: Colors.grey[600], size: 20.sp),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final String? avatarUrl;

  const _TypingIndicator({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 20.sp),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              'Typing...',
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
