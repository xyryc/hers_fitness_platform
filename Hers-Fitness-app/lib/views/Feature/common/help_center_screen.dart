import 'package:fitness/controllers/member/help_center_controller.dart';
import 'package:fitness/models/faq_model.dart';
import 'package:fitness/models/help_ticket_model.dart';
import 'package:fitness/services/faq_service.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int _selectedTab = 0; // 0 = FAQ, 1 = Ticket
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late final HelpCenterController _controller;
  final _faqService = FaqService();

  // FAQ state
  List<FaqModel> _allFaqs = [];
  final Set<String> _expandedIds = {};
  bool _faqLoading = true;
  String? _faqError;

  List<FaqModel> get _filteredFaqs {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _allFaqs;
    return _allFaqs.where((f) => f.matches(query)).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<HelpCenterController>()
        ? Get.find<HelpCenterController>()
        : Get.put(HelpCenterController());
    _loadFaqs();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _faqLoading = true;
      _faqError = null;
    });
    try {
      final faqs = await _faqService.getFaqs();
      if (mounted) {
        setState(() {
          _allFaqs = faqs;
          // Auto-expand first item if any
          if (faqs.isNotEmpty) _expandedIds.add(faqs.first.id);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _faqError = 'Could not load FAQs.');
    } finally {
      if (mounted) setState(() => _faqLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final success = await _controller.submitTicket(
      title: _titleController.text,
      body: _bodyController.text,
    );
    if (success) {
      _titleController.clear();
      _bodyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Column(
              children: [
                SizedBox(height: 24.h),
                _buildTabs(),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildFAQView()
                      : _buildTicketView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Row(
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
            child: Center(
              child: AppText(
                "Help Center",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton("FAQ", 0)),
          Expanded(child: _buildTabButton("Ticket", 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.actionPrimary.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: AppText(
            title,
            style: AppTextStyles.base16Medium.copyWith(
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // ─── FAQ tab ──────────────────────────────────────────────────────────────

  Widget _buildFAQView() {
    if (_faqLoading) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        children: [
          _buildSearchBar(),
          SizedBox(height: 48.h),
          Center(
            child: CircularProgressIndicator(color: AppColors.actionPrimary),
          ),
        ],
      );
    }

    if (_faqError != null) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        children: [
          _buildSearchBar(),
          SizedBox(height: 48.h),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 40.w, color: Colors.redAccent),
                SizedBox(height: 12.h),
                AppText(
                  _faqError!,
                  style: AppTextStyles.sm14Regular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: _loadFaqs,
                  child: AppText(
                    'Retry',
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.actionPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final faqs = _filteredFaqs;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        _buildSearchBar(),
        SizedBox(height: 24.h),
        if (faqs.isEmpty)
          Center(
            child: AppText(
              'No results found.',
              style: AppTextStyles.sm14Regular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...faqs.map(_buildFAQItem),
      ],
    );
  }

  Widget _buildSearchBar() {
    return CustomTextField(
      controller: _searchController,
      hintText: "Search our FAQ...",
      suffixIcon: const Icon(Icons.search, color: Colors.black),
      borderColor: AppColors.actionPrimary.withValues(alpha: 0.3),
    );
  }

  Widget _buildFAQItem(FaqModel item) {
    final isExpanded = _expandedIds.contains(item.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedIds.remove(item.id);
        } else {
          _expandedIds.add(item.id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isExpanded ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            if (!isExpanded)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    item.question,
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: isExpanded ? Colors.white : Colors.black,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.actionPrimary.withValues(alpha: 0.8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: isExpanded
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? Colors.white : Colors.black,
                    size: 20.w,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 16.h),
              AppText(
                item.answer,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Ticket tab ───────────────────────────────────────────────────────────

  Widget _buildTicketView() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        // ── Submit form ──────────────────────────────────────────────────
        _buildSectionLabel("Submit a Ticket"),
        SizedBox(height: 12.h),
        CustomTextField(
          controller: _titleController,
          hintText: "Tell us your problem…",
          borderColor: AppColors.actionPrimary.withValues(alpha: 0.3),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _bodyController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Describe your issue in detail…",
                  hintStyle: AppTextStyles.sm14Regular.copyWith(
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTextStyles.sm14Regular.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16.w,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4.w),
                  Obx(
                    () => AppText(
                      _controller.isSubmitting.value
                          ? "Sending…"
                          : "Send ticket",
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Obx(() {
          final sending = _controller.isSubmitting.value;
          return AppButton(
            onTap: sending ? () {} : _onSend,
            text: sending ? "Sending…" : "Send",
          );
        }),

        SizedBox(height: 32.h),

        // ── Ticket history ────────────────────────────────────────────────
        _buildSectionLabel("My Tickets"),
        SizedBox(height: 12.h),

        Obx(() {
          if (_controller.isLoadingTickets.value) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.actionPrimary,
                ),
              ),
            );
          }
          final list = _controller.tickets;
          if (list.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48.w,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      "No tickets yet",
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: list
                .map(
                  (t) =>
                      _TicketCard(ticket: t, onTap: () => _showTicketDetail(t)),
                )
                .toList(),
          );
        }),

        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return AppText(
      text,
      style: AppTextStyles.base16SemiBold.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ─── Ticket detail bottom sheet ───────────────────────────────────────────

  void _showTicketDetail(HelpTicketModel ticket) async {
    // Fetch latest version (may have adminNote now)
    final detail = await _controller.getTicketDetail(ticket.id);
    final t = detail ?? ticket;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketDetailSheet(ticket: t),
    );
  }
}

// ─── Ticket Card ──────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
  final HelpTicketModel ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, dotColor) = _statusColors(ticket.status);
    final dateStr = ticket.createdAt != null
        ? DateFormat('MMM d, yyyy').format(ticket.createdAt!.toLocal())
        : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot indicator
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    ticket.title,
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    dateStr,
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText(
                ticket.statusLabel,
                style: AppTextStyles.xs12Regular.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color bg, Color dot) _statusColors(String status) {
    switch (status.toUpperCase()) {
      case 'IN_REVIEW':
        return (const Color(0xFFEFF6FF), const Color(0xFF3B82F6));
      case 'RESOLVED':
        return (const Color(0xFFF0FDF4), const Color(0xFF22C55E));
      case 'CLOSED':
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
      case 'OPEN':
      default:
        return (const Color(0xFFFFFBEB), const Color(0xFFF59E0B));
    }
  }
}

// ─── Ticket Detail Bottom Sheet ───────────────────────────────────────────────

class _TicketDetailSheet extends StatelessWidget {
  const _TicketDetailSheet({required this.ticket});
  final HelpTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, dotColor) = _statusColors(ticket.status);
    final createdStr = ticket.createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(ticket.createdAt!.toLocal())
        : '—';
    final resolvedStr = ticket.resolvedAt != null
        ? DateFormat(
            'MMM d, yyyy • h:mm a',
          ).format(ticket.resolvedAt!.toLocal())
        : null;

    return Container(
      margin: EdgeInsets.only(top: 60.h),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          // Header bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    "Ticket Detail",
                    style: AppTextStyles.base16SemiBold.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppText(
                    ticket.statusLabel,
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: dotColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  AppText(
                    ticket.title,
                    style: AppTextStyles.base16SemiBold.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    "Submitted: $createdStr",
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (resolvedStr != null) ...[
                    SizedBox(height: 2.h),
                    AppText(
                      "Resolved: $resolvedStr",
                      style: AppTextStyles.xs12Regular.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],

                  SizedBox(height: 20.h),
                  _buildCard(
                    label: "Your Message",
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: AppColors.actionPrimary,
                    child: AppText(
                      ticket.body,
                      style: AppTextStyles.sm14Regular.copyWith(height: 1.6),
                    ),
                  ),

                  if (ticket.adminNote != null) ...[
                    SizedBox(height: 16.h),
                    _buildCard(
                      label: "Admin Reply",
                      icon: Icons.support_agent_rounded,
                      iconColor: Colors.green.shade600,
                      child: AppText(
                        ticket.adminNote!,
                        style: AppTextStyles.sm14Regular.copyWith(height: 1.6),
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            color: Colors.grey,
                            size: 20.w,
                          ),
                          SizedBox(width: 10.w),
                          AppText(
                            "Waiting for admin response…",
                            style: AppTextStyles.sm14Regular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18.w),
              SizedBox(width: 8.w),
              AppText(
                label,
                style: AppTextStyles.sm14Medium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  (Color bg, Color dot) _statusColors(String status) {
    switch (status.toUpperCase()) {
      case 'IN_REVIEW':
        return (const Color(0xFFEFF6FF), const Color(0xFF3B82F6));
      case 'RESOLVED':
        return (const Color(0xFFF0FDF4), const Color(0xFF22C55E));
      case 'CLOSED':
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
      case 'OPEN':
      default:
        return (const Color(0xFFFFFBEB), const Color(0xFFF59E0B));
    }
  }
}
