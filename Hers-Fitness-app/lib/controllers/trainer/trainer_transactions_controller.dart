import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/trainer_transaction_model.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:get/get.dart';

class TrainerTransactionsController extends GetxController {
  TrainerTransactionsController({UserService? userService})
    : _userService = userService ?? UserService();

  final UserService _userService;

  final transactions = RxList<TrainerTransactionModel>();
  final isLoading = false.obs;

  // Pagination state
  int _currentPage = 1;
  static const int _limit = 20;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  /// Initial / refresh load — resets to page 1.
  Future<void> fetchTransactions({bool showError = false}) async {
    try {
      isLoading.value = true;
      hasMore.value = true;
      _currentPage = 1;
      final result = await _userService.getTrainerTransactions(
        page: _currentPage,
        limit: _limit,
      );
      transactions.value = result;
      if (result.length < _limit) hasMore.value = false;
    } on ApiException catch (e) {
      if (showError) {
        showAppSnackbar(
          'Could not load transactions',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Could not load transactions',
          'Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load the next page — called when the user scrolls to the bottom.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      _currentPage++;
      final result = await _userService.getTrainerTransactions(
        page: _currentPage,
        limit: _limit,
      );
      transactions.addAll(result);
      if (result.length < _limit) hasMore.value = false;
    } on ApiException catch (_) {
      _currentPage--; // roll back so the next pull retries the same page
    } catch (_) {
      _currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
