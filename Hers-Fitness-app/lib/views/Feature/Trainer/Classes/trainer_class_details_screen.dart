import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/services/trainer_class_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/utils/booking_action_visibility.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TrainerClassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const TrainerClassDetailsScreen({super.key, required this.classData});

  @override
  State<TrainerClassDetailsScreen> createState() =>
      _TrainerClassDetailsScreenState();
}

class _TrainerClassDetailsScreenState extends State<TrainerClassDetailsScreen> {
  final TrainerClassService _classService = TrainerClassService();
  Future<Map<String, dynamic>>? _detailsFuture;
  String? _completingBookingId;

  @override
  void initState() {
    super.initState();
    final id = _readString(widget.classData, const ['id']);
    if (id.isNotEmpty) {
      _detailsFuture = _classService.getClassDetails(id);
    }
  }

  void _refreshDetails(String id) {
    setState(() {
      _detailsFuture = _classService.getClassDetails(id);
    });
  }

  Future<void> _completeTrainerBooking(
    String bookingId,
    Map<String, dynamic> classData,
  ) async {
    if (_completingBookingId != null) return;

    final classId = _readString(classData, const ['id']);
    setState(() => _completingBookingId = bookingId);

    try {
      await _classService.completeBooking(bookingId);
      showAppSnackbar(
        'Class completed',
        'Trainer confirmation has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (classId.isNotEmpty && mounted) _refreshDetails(classId);
    } on ApiException catch (error) {
      showAppSnackbar(
        'Complete failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Complete failed',
        'Could not mark this booking as complete.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _completingBookingId = null);
    }
  }

  Future<void> _acceptTrainerReschedule(
    String bookingId,
    Map<String, dynamic> classData,
  ) async {
    if (_completingBookingId != null) return;

    final classId = _readString(classData, const ['id']);
    setState(() => _completingBookingId = bookingId);

    try {
      await _classService.acceptReschedule(bookingId);
      showAppSnackbar(
        'Reschedule accepted',
        'You have accepted the member\'s reschedule request.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (classId.isNotEmpty && mounted) _refreshDetails(classId);
    } on ApiException catch (error) {
      showAppSnackbar(
        'Accept failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Accept failed',
        'Could not accept the reschedule request.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _completingBookingId = null);
    }
  }

  Future<void> _openRescheduleSheet(Map<String, dynamic> classData) async {
    final id = _readString(classData, const ['id']);
    if (id.isEmpty) {
      showAppSnackbar(
        'Missing class',
        'Class id was not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final didSubmit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleBottomSheet(
        classId: id,
        classService: _classService,
        durationMinutes: _readInt(classData, const [
          'durationMinutes',
          'duration_minutes',
          'duration',
        ]),
      ),
    );

    if (didSubmit != true || !mounted) return;

    showAppSnackbar(
      'Reschedule requested',
      'Proposed slot sent for member approval.',
      snackPosition: SnackPosition.BOTTOM,
    );
    _refreshDetails(id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _detailsFuture ?? Future.value(<String, dynamic>{}),
        _resolveTrainerUserId(),
      ]),
      builder: (context, snapshot) {
        final classData = snapshot.hasData
            ? (snapshot.data![0] as Map<String, dynamic>).isEmpty
                  ? widget.classData
                  : snapshot.data![0] as Map<String, dynamic>
            : widget.classData;
        final trainerUserId = snapshot.hasData
            ? snapshot.data![1] as String?
            : null;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        (_detailsFuture != null)
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.actionPrimary,
                        ),
                      )
                    : snapshot.hasError
                    ? _ErrorState(
                        message: snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : 'Could not load class details.',
                      )
                    : _DetailsBody(
                        classData: classData,
                        completingBookingId: _completingBookingId,
                        trainerUserId: trainerUserId,
                        onReschedule: () => _openRescheduleSheet(classData),
                        onCompleteBooking: (bookingId) =>
                            _completeTrainerBooking(bookingId, classData),
                        onAcceptReschedule: (bookingId) =>
                            _acceptTrainerReschedule(bookingId, classData),
                        onRefresh: () => _refreshDetails(
                          _readString(classData, const ['id']),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _resolveTrainerUserId() async {
    try {
      final user = await UserService().getCurrentUser();
      return user.trainerUserId ?? user.id;
    } catch (_) {
      return null;
    }
  }
}

class _DetailsBody extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String? completingBookingId;
  final String? trainerUserId;
  final VoidCallback onReschedule;
  final ValueChanged<String> onCompleteBooking;
  final ValueChanged<String> onAcceptReschedule;
  final VoidCallback onRefresh;

  const _DetailsBody({
    required this.classData,
    required this.completingBookingId,
    this.trainerUserId,
    required this.onReschedule,
    required this.onCompleteBooking,
    required this.onAcceptReschedule,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final title = _readString(classData, const ['name', 'title']) ?? 'Class';
    final classType = _displayClassType(
      _readString(classData, const ['classType', 'class_type', 'apiClassType']),
    );
    final sessionFormat = _displaySessionFormat(
      _readString(classData, const [
        'sessionFormat',
        'session_format',
        'apiSessionFormat',
      ]),
    );
    final duration = _readInt(classData, const [
      'durationMinutes',
      'duration_minutes',
      'duration',
    ]);
    final price = _readDouble(classData, const [
      'pricePerMember',
      'price_per_member',
      'price',
    ]);
    final slots = _readList(classData, const <String>[
      'availableSlots',
      'available_slots',
      'availabilitySlots',
      'availability_slots',
    ]);
    final firstSlot = slots.isNotEmpty ? _asMap(slots.first) : null;
    final bookedSlots = _readList(classData, const <String>[
      'joinedMembers',
      'joined_members',
      'bookedSlots',
      'booked_slots',
    ]);
    final isGroup = sessionFormat.toLowerCase() == 'group';
    final bookedMemberCount = _readInt(classData, const [
      'bookedMemberCount',
      'booked_member_count',
      'bookedCount',
    ]);
    final capacity = _readInt(classData, const ['capacity', 'maxMembers']);

    final rescheduleStatus = _readString(classData, const [
      'rescheduleStatus',
      'reschedule_status',
    ]);
    final rescheduleNote = _readString(classData, const [
      'rescheduleNote',
      'reschedule_note',
    ]);
    final rescheduleRequestedAt = _readString(classData, const [
      'rescheduleRequestedAt',
      'reschedule_requested_at',
    ]);
    final proposedSlots = _readList(classData, const <String>[
      'proposedRescheduleSlots',
      'proposed_reschedule_slots',
    ]);

    final hasRescheduleState =
        rescheduleStatus.isNotEmpty ||
        rescheduleNote.isNotEmpty ||
        rescheduleRequestedAt.isNotEmpty ||
        proposedSlots.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              _ClassImage(slot: firstSlot, classData: classData),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10.h,
                left: 20.w,
                child: const _BackButton(),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 120.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppText(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.twoXL24SemiBold.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (isGroup)
                      _CapacityPanel(
                        bookedCount: bookedMemberCount,
                        capacity: capacity,
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _Badge(text: classType),
                    SizedBox(width: 8.w),
                    _Badge(text: sessionFormat),
                    const Spacer(),
                    AppText(
                      '\$$price',
                      style: AppTextStyles.lg18SemiBold.copyWith(
                        color: AppColors.actionPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    AppText(
                      ' / session',
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                _DetailsPanel(
                  title: 'Schedule & Reschedule',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoItem(
                        label: 'Class Date',
                        value: _displayDate(firstSlot),
                      ),
                      SizedBox(height: 18.h),
                      _InfoItem(
                        label: 'Class Time',
                        value: _displayTime(firstSlot, duration, classData),
                      ),
                      if (hasRescheduleState) ...[
                        SizedBox(height: 18.h),
                        _RescheduleStatusPanel(
                          status: rescheduleStatus,
                          note: rescheduleNote,
                          requestedAt: rescheduleRequestedAt,
                          slots: proposedSlots,
                        ),
                      ],
                      SizedBox(height: 18.h),
                      GestureDetector(
                        onTap: onReschedule,
                        child: Container(
                          height: 42.h,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.actionSecondary,
                            borderRadius: BorderRadius.circular(7.r),
                          ),
                          child: AppText(
                            'Rescheduled',
                            style: AppTextStyles.sm14SemiBold.copyWith(
                              color: AppColors.textInverse,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                AppText(
                  'Join Members',
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 14.h),
                if (bookedSlots.isEmpty)
                  const _EmptyMembers()
                else
                  ...bookedSlots.map((item) {
                    final member = _memberMap(item);
                    final booking = _bookingActionSource(
                      item,
                      classData,
                      firstSlot,
                    );
                    final bookingId = _readString(booking, const [
                      'bookingId',
                      'booking_id',
                      'id',
                    ]);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _MemberTile(
                        member: member,
                        booking: booking,
                        trainerUserId: trainerUserId,
                        isCompleting:
                            bookingId.isNotEmpty &&
                            bookingId == completingBookingId,
                        onComplete: bookingId.isEmpty
                            ? null
                            : () => onCompleteBooking(bookingId),
                        onAcceptReschedule: bookingId.isEmpty
                            ? null
                            : () => onAcceptReschedule(bookingId),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayDate(Map<String, dynamic>? slot) {
    final startAt = _readString(slot, const ['startAt', 'start_at']);
    final parsedStartAt = startAt.isEmpty ? null : DateTime.tryParse(startAt);
    if (parsedStartAt != null) {
      return DateFormat('EEEE, MMMM d, yyyy').format(parsedStartAt);
    }

    final date = _readString(slot, const ['date', 'scheduledDate']);
    final parsedDate = date.isEmpty ? null : DateTime.tryParse(date);
    if (parsedDate != null) {
      return DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);
    }

    return date;
  }

  String _displayTime(
    Map<String, dynamic>? slot,
    int duration,
    Map<String, dynamic> classData,
  ) {
    final start = _timeText(
      _readString(slot, const ['startTime', 'start_time']),
    );
    final end = _timeText(_readString(slot, const ['endTime', 'end_time']));
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end (${duration}m)';
    }

    final fallback = _readString(classData, const ['time']);
    return fallback.isEmpty ? '${duration}m' : '$fallback (${duration}m)';
  }
}

class _CapacityPanel extends StatelessWidget {
  final int bookedCount;
  final int capacity;

  const _CapacityPanel({required this.bookedCount, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 16.sp,
            color: AppColors.iconSecondary,
          ),
          SizedBox(width: 6.w),
          AppText(
            '$bookedCount/$capacity',
            style: AppTextStyles.xs12SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassImage extends StatelessWidget {
  final Map<String, dynamic>? slot;
  final Map<String, dynamic> classData;

  const _ClassImage({required this.slot, required this.classData});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        _readString(slot, const ['imageUrl', 'image_url', 'image']).isNotEmpty
        ? _readString(slot, const ['imageUrl', 'image_url', 'image'])
        : _readString(classData, const [
            'trainerImageUrl',
            'imageUrl',
            'image_url',
          ]);

    return Container(
      height: 240.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.borderPrimary,
        image: imageUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl.isEmpty
          ? Center(
              child: Icon(
                Icons.image_outlined,
                size: 48.sp,
                color: AppColors.iconSecondary,
              ),
            )
          : null,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: AppText(
        text,
        style: AppTextStyles.sm14SemiBold.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailsPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.xs12SemiBold.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8.h),
        AppText(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sm14SemiBold.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, String> member;
  final Map<String, dynamic> booking;
  final String? trainerUserId;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onAcceptReschedule;

  const _MemberTile({
    required this.member,
    required this.booking,
    this.trainerUserId,
    required this.isCompleting,
    this.onComplete,
    this.onAcceptReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final showMarkComplete = canShowTrainerComplete(booking);
    final showAcceptReschedule = canShowTrainerAcceptReschedule(
      booking,
      trainerUserId,
    );
    final showChecking = canShowTrainerChecking(booking, trainerUserId);

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  member['image'] ?? '',
                  width: 58.w,
                  height: 58.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 58.w,
                    height: 58.w,
                    color: AppColors.borderPrimary,
                    child: Icon(
                      Icons.person_rounded,
                      size: 24.sp,
                      color: AppColors.iconSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      member['name'] ?? 'Member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.base16SemiBold.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      member['subtitle'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.xs12SemiBold.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showMarkComplete) ...[
            SizedBox(height: 12.h),
            _TrainerBookingButton(
              label: 'Mark as Complete',
              isLoading: isCompleting,
              onTap: isCompleting ? null : onComplete,
            ),
          ] else if (showAcceptReschedule) ...[
            SizedBox(height: 12.h),
            _TrainerBookingButton(
              label: 'Accept New Time',
              isLoading: isCompleting,
              onTap: isCompleting ? null : onAcceptReschedule,
            ),
          ] else if (showChecking) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              height: 42.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: AppText(
                'Checking...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.xs12SemiBold.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainerBookingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _TrainerBookingButton({
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.h,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.actionSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : AppText(
                label,
                style: AppTextStyles.xs12SemiBold.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}

class _RescheduleStatusPanel extends StatelessWidget {
  final String status;
  final String note;
  final String requestedAt;
  final List<dynamic> slots;

  const _RescheduleStatusPanel({
    required this.status,
    required this.note,
    required this.requestedAt,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16.sp,
                color: AppColors.actionPrimary,
              ),
              SizedBox(width: 8.w),
              AppText(
                status.isEmpty ? 'Reschedule Pending' : status,
                style: AppTextStyles.xs12SemiBold.copyWith(
                  color: AppColors.actionPrimary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            SizedBox(height: 8.h),
            AppText(
              note,
              style: AppTextStyles.xs12Regular.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      alignment: Alignment.center,
      child: AppText(
        'No members joined yet.',
        style: AppTextStyles.sm14Medium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: AppColors.statusError,
            ),
            SizedBox(height: 16.h),
            AppText(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _RescheduleBottomSheet extends StatefulWidget {
  final String classId;
  final TrainerClassService classService;
  final int durationMinutes;

  const _RescheduleBottomSheet({
    required this.classId,
    required this.classService,
    required this.durationMinutes,
  });

  @override
  State<_RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<_RescheduleBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// Helper methods
String _readString(dynamic source, List<String> keys) {
  if (source == null) return '';
  for (final key in keys) {
    final value = source[key];
    if (value != null && value.toString().toLowerCase() != 'null') {
      return value.toString().trim();
    }
  }
  return '';
}

int _readInt(dynamic source, List<String> keys) {
  if (source == null) return 0;
  for (final key in keys) {
    final value = source[key];
    if (value is int) return value;
    if (value != null) return int.tryParse(value.toString()) ?? 0;
  }
  return 0;
}

double _readDouble(dynamic source, List<String> keys) {
  if (source == null) return 0.0;
  for (final key in keys) {
    final value = source[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value != null) return double.tryParse(value.toString()) ?? 0.0;
  }
  return 0.0;
}

List<dynamic> _readList(dynamic source, List<String> keys) {
  if (source == null) return [];
  for (final key in keys) {
    final value = source[key];
    if (value is List) return value;
  }
  return [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

String _displayClassType(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'IN_PERSON':
      return 'in person';
    case 'ONLINE':
      return 'online';
    default:
      return (value ?? 'N/A').toLowerCase();
  }
}

String _displaySessionFormat(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PRIVATE':
      return 'One-to-one';
    case 'GROUP':
      return 'Group';
    default:
      return value ?? 'Session';
  }
}

String _timeText(String? value) {
  final text = value ?? '';
  final parts = text.split(':');
  if (parts.length < 2) return text;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return text;

  return DateFormat('hh:mm a').format(DateTime(2026, 1, 1, hour, minute));
}

Map<String, dynamic> _bookingActionSource(
  dynamic item,
  Map<String, dynamic> classData,
  Map<String, dynamic>? slot,
) {
  final booking = _asMap(item);
  final locationTime = _asMap(
    booking['locationTime'] ?? booking['location_time'],
  );

  String first(List<String> keys) {
    final val = _readString(booking, keys);
    if (val.isNotEmpty) return val;
    final val2 = _readString(locationTime, keys);
    if (val2.isNotEmpty) return val2;
    final val3 = _readString(slot, keys);
    if (val3.isNotEmpty) return val3;
    return _readString(classData, keys);
  }

  return {
    ...booking,
    'bookingId': _readString(booking, const ['bookingId', 'booking_id', 'id']),
    'bookingStatus':
        first(const ['bookingStatus', 'booking_status', 'status']).isNotEmpty
        ? first(const ['bookingStatus', 'booking_status', 'status'])
        : 'CONFIRMED',
    'paymentStatus': first(const ['paymentStatus', 'payment_status']),
    'scheduledDate': first(const [
      'scheduledDate',
      'scheduled_date',
      'date',
      'slotDate',
      'slot_date',
    ]),
    'startTime': first(const [
      'startTime',
      'start_time',
      'time',
      'scheduledStartTime',
    ]),
    'endTime': first(const ['endTime', 'end_time', 'scheduledEndTime']),
    'startAt': first(const ['startAt', 'start_at']),
    'endAt': first(const ['endAt', 'end_at']),
    'memberCompletedAt': first(const [
      'memberCompletedAt',
      'member_completed_at',
    ]),
    'trainerCompletedAt': first(const [
      'trainerCompletedAt',
      'trainer_completed_at',
    ]),
    'completedAt': first(const ['completedAt', 'completed_at']),
    'rescheduleRequestedByUserId': first(const [
      'rescheduleRequestedByUserId',
      'reschedule_requested_by_user_id',
    ]),
  };
}

Map<String, String> _memberMap(dynamic item) {
  final booking = _asMap(item);
  final nested = _asMap(
    booking['member'] ?? booking['memberUser'] ?? booking['user'],
  );

  // flat structure (joinedMembers) or nested (bookedSlots)
  final nameFromFlat = _readString(booking, const [
    'name',
    'displayName',
    'display_name',
    'fullName',
    'full_name',
  ]);
  final nameFromNested = _readString(nested, const [
    'name',
    'displayName',
    'display_name',
    'fullName',
    'full_name',
  ]);
  final firstName = _readString(nested.isNotEmpty ? nested : booking, const [
    'firstName',
    'first_name',
  ]);
  final lastName = _readString(nested.isNotEmpty ? nested : booking, const [
    'lastName',
    'last_name',
  ]);
  final resolvedName = nameFromFlat.isNotEmpty
      ? nameFromFlat
      : nameFromNested.isNotEmpty
      ? nameFromNested
      : '$firstName $lastName'.trim();

  final image =
      _readString(booking, const [
        'profileImageUrl',
        'profile_image_url',
        'imageUrl',
        'image_url',
        'avatar',
      ]).isNotEmpty
      ? _readString(booking, const [
          'profileImageUrl',
          'profile_image_url',
          'imageUrl',
          'image_url',
          'avatar',
        ])
      : _readString(nested, const [
          'imageUrl',
          'image_url',
          'profileImageUrl',
          'profile_image_url',
          'avatar',
        ]);

  return {
    'name': resolvedName.isEmpty ? 'Member' : resolvedName,
    'subtitle': 'Class Participant',
    'image': image,
  };
}
