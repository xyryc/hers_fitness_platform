import 'package:intl/intl.dart';

class TrainerReviewModel {
  final String id;
  final String memberUserId;
  final String trainerUserId;
  final double rating;
  final String comment;
  final String memberName;
  final String? memberImageUrl;
  final DateTime? createdAt;

  const TrainerReviewModel({
    required this.id,
    required this.memberUserId,
    required this.trainerUserId,
    required this.rating,
    required this.comment,
    required this.memberName,
    this.memberImageUrl,
    this.createdAt,
  });

  factory TrainerReviewModel.fromJson(Map<String, dynamic> json) {
    final member = _object(json['member']) ?? const <String, dynamic>{};

    return TrainerReviewModel(
      id: _readString(json, const ['id']) ?? '',
      memberUserId:
          _readString(json, const ['memberUserId', 'member_user_id']) ?? '',
      trainerUserId:
          _readString(json, const ['trainerUserId', 'trainer_user_id']) ?? '',
      rating: double.tryParse(_readString(json, const ['rating']) ?? '') ?? 0,
      comment: _readString(json, const ['comment', 'review', 'text']) ?? '',
      memberName:
          _readString(member, const ['name', 'displayName']) ?? 'Member',
      memberImageUrl: _readString(member, const [
        'profileImageUrl',
        'profile_image_url',
        'imageUrl',
        'image_url',
      ]),
      createdAt: DateTime.tryParse(
        _readString(json, const ['createdAt', 'created_at']) ?? '',
      ),
    );
  }

  Map<String, String> toUiMap() {
    return {
      'name': memberName,
      'rating': rating.toStringAsFixed(1),
      'time': timeAgo,
      'text': comment,
      'image': memberImageUrl ?? '',
    };
  }

  String get timeAgo {
    final created = createdAt;
    if (created == null) return '';

    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(created);
  }

  static Map<String, dynamic>? _object(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }
}
