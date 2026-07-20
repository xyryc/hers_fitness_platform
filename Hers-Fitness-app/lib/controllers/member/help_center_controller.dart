import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/help_ticket_model.dart';
import 'package:fitness/services/help_ticket_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:get/get.dart';

class HelpCenterController extends GetxController {
  HelpCenterController({HelpTicketService? service})
    : _service = service ?? HelpTicketService();

  final HelpTicketService _service;

  final tickets = RxList<HelpTicketModel>();
  final isSubmitting = false.obs;
  final isLoadingTickets = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyTickets();
  }

  /// Submit a new support ticket
  Future<bool> submitTicket({
    required String title,
    required String body,
  }) async {
    if (title.trim().isEmpty) {
      showAppSnackbar(
        'Validation',
        'Please enter a title for your issue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (body.trim().isEmpty) {
      showAppSnackbar(
        'Validation',
        'Please describe your issue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSubmitting.value = true;
      final ticket = await _service.submitTicket(title: title, body: body);
      tickets.insert(0, ticket); // prepend so it shows at top
      showAppSnackbar(
        'Ticket submitted',
        'Your ticket has been received. We\'ll get back to you soon.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Submission failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      showAppSnackbar(
        'Submission failed',
        'Could not submit ticket. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Load all tickets for the current user
  Future<void> fetchMyTickets({bool showError = false}) async {
    try {
      isLoadingTickets.value = true;
      tickets.value = await _service.getMyTickets();
    } on ApiException catch (e) {
      if (showError) {
        showAppSnackbar(
          'Load failed',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Load failed',
          'Could not load your tickets.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingTickets.value = false;
    }
  }

  /// Fetch a single ticket's latest state (including adminNote)
  Future<HelpTicketModel?> getTicketDetail(String id) async {
    try {
      final detail = await _service.getTicketById(id);
      // Update local list entry
      final idx = tickets.indexWhere((t) => t.id == id);
      if (idx != -1) tickets[idx] = detail;
      return detail;
    } on ApiException catch (e) {
      showAppSnackbar(
        'Load failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (_) {
      return null;
    }
  }
}
