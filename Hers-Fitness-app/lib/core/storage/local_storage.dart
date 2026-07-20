import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _memberCoverPhotoKey = 'member_cover_photo';
  static const _trainerCoverPhotoKey = 'trainer_cover_photo';

  Future<void> saveMemberCoverPhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memberCoverPhotoKey, path);
  }

  Future<String?> getMemberCoverPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_memberCoverPhotoKey);
  }

  Future<void> saveTrainerCoverPhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trainerCoverPhotoKey, path);
  }

  Future<String?> getTrainerCoverPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_trainerCoverPhotoKey);
  }
}
