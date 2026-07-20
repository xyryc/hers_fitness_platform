import 'package:get/get.dart';

class TrainerBookmarkController extends GetxController {
  final bookmarkedTrainers = <String, Map<String, dynamic>>{}.obs;

  bool isBookmarked(Map<String, dynamic> trainer) {
    final key = _trainerKey(trainer);
    return key != null && bookmarkedTrainers.containsKey(key);
  }

  void toggleTrainer(Map<String, dynamic> trainer) {
    final key = _trainerKey(trainer);
    if (key == null) return;

    if (bookmarkedTrainers.containsKey(key)) {
      bookmarkedTrainers.remove(key);
      return;
    }

    bookmarkedTrainers[key] = Map<String, dynamic>.from(trainer);
  }

  List<Map<String, dynamic>> get savedTrainers =>
      bookmarkedTrainers.values.toList();

  String? _trainerKey(Map<String, dynamic> trainer) {
    for (final key in const [
      'trainerUserId',
      'trainer_user_id',
      'userId',
      'user_id',
      'id',
      'name',
    ]) {
      final value = trainer[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }
}
