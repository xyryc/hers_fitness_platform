import 'package:fitness/utils/image_url.dart';

class TrainerProfileModel {
  final String? id;
  final String? trainerUserId;
  final String name;
  final String specialty;
  final String price;
  final String experience;
  final double rating;
  final int? reviewCount;
  final String imageUrl;
  final String distance;
  final String bio;
  final double? lat;
  final double? lng;
  final bool isOnline;
  final String? lastSeen;
  final String? locationLabel;
  final double? distanceMeters;

  const TrainerProfileModel({
    this.id,
    this.trainerUserId,
    required this.name,
    required this.specialty,
    required this.price,
    required this.experience,
    required this.rating,
    this.reviewCount,
    required this.imageUrl,
    required this.distance,
    required this.bio,
    this.lat,
    this.lng,
    this.isOnline = false,
    this.lastSeen,
    this.locationLabel,
    this.distanceMeters,
  });

  factory TrainerProfileModel.fromJson(Map<String, dynamic> json) {
    final user = _object(json['user']);
    final source = user == null ? json : <String, dynamic>{...json, ...user};
    final profile =
        _object(json['trainerProfile']) ??
        _object(json['trainer_profile']) ??
        _object(source['trainerProfile']) ??
        _object(source['trainer_profile']) ??
        _object(source['profile']) ??
        const <String, dynamic>{};
    final location =
        _object(json['location']) ??
        _object(json['liveLocation']) ??
        _object(json['live_location']) ??
        _object(source['location']) ??
        _object(source['liveLocation']) ??
        _object(source['live_location']) ??
        _object(profile['location']) ??
        const <String, dynamic>{};

    final firstName = _readString(source, const ['firstName', 'first_name']);
    final lastName = _readString(source, const ['lastName', 'last_name']);
    final combinedName = [
      firstName,
      lastName,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    final name =
        _readString(source, const [
          'name',
          'displayName',
          'display_name',
          'fullName',
          'full_name',
        ]) ??
        (combinedName.isEmpty ? null : combinedName) ??
        'Trainer';
    final priceValue =
        _readString(profile, const [
          'price',
          'startingPrice',
          'starting_price',
          'pricePerSession',
          'price_per_session',
          'pricePerMember',
          'price_per_member',
        ]) ??
        _readString(source, const [
          'price',
          'startingPrice',
          'starting_price',
          'pricePerSession',
          'price_per_session',
        ]);

    final trainerUserId =
        _readString(source, const [
          'trainerUserId',
          'trainer_user_id',
          'userId',
          'user_id',
        ]) ??
        (user == null
            ? null
            : _readString(user, const ['id', 'userId', 'user_id'])) ??
        _readString(source, const ['id']);

    return TrainerProfileModel(
      id: _readString(source, const ['id', 'userId', 'user_id']),
      trainerUserId: trainerUserId,
      name: name,
      specialty:
          _readString(profile, const [
            'specialty',
            'expertise',
            'classesTaught',
            'classes_taught',
          ]) ??
          _readString(source, const [
            'specialty',
            'expertise',
            'classesTaught',
            'classes_taught',
          ]) ??
          'Fitness Trainer',
      price: _formatPrice(priceValue),
      experience:
          _readString(profile, const [
            'instructorExperience',
            'instructor_experience',
            'experience',
          ]) ??
          _readString(source, const [
            'instructorExperience',
            'instructor_experience',
            'experience',
          ]) ??
          '',
      rating:
          _readDouble(source, const [
            'rating',
            'averageRating',
            'average_rating',
          ]) ??
          _readDouble(profile, const [
            'rating',
            'averageRating',
            'average_rating',
          ]) ??
          0,
      reviewCount:
          _readInt(source, const ['reviewCount', 'review_count', 'reviews']) ??
          _readInt(profile, const ['reviewCount', 'review_count', 'reviews']),
      imageUrl: _readImageUrl(source, profile) ?? '',
      distance: _formatDistance(
        _readDouble(source, const ['distanceMeters', 'distance_meters']),
        _readDouble(source, const ['distance', 'distanceKm', 'distance_km']) ??
            _readDouble(profile, const [
              'distance',
              'distanceKm',
              'distance_km',
            ]),
      ),
      bio:
          _readString(profile, const ['bio', 'description']) ??
          _readString(source, const ['bio', 'description']) ??
          '',
      lat:
          _readDouble(location, const ['lat', 'latitude']) ??
          _readDouble(source, const ['lat', 'latitude']),
      lng:
          _readDouble(location, const ['lng', 'longitude']) ??
          _readDouble(source, const ['lng', 'longitude']),
      isOnline:
          _readBool(source, const ['isOnline', 'is_online']) ??
          _readBool(profile, const ['isOnline', 'is_online']) ??
          false,
      lastSeen:
          _readString(source, const ['lastSeen', 'last_seen']) ??
          _readString(profile, const ['lastSeen', 'last_seen']),
      locationLabel:
          _readString(source, const ['locationLabel', 'location_label']) ??
          _readString(profile, const ['locationLabel', 'location_label']),
      distanceMeters: _readDouble(source, const [
        'distanceMeters',
        'distance_meters',
      ]),
    );
  }

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'trainerUserId': trainerUserId,
      'name': name,
      'expertise': specialty,
      'rating': rating,
      'price': price,
      'experience': experience,
      'imageUrl': imageUrl,
      'distance': distance,
      'reviewCount': reviewCount,
      'bio': bio,
      'lat': lat,
      'lng': lng,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'locationLabel': locationLabel,
      'distanceMeters': distanceMeters,
      'isActiveNow': locationLabel == 'Active Now',
    };
  }

  static String _formatPrice(String? value) {
    if (value == null || value.isEmpty) return 'Price unavailable';
    if (value.contains('/')) return value;
    if (value.startsWith(r'$')) return '$value/session';
    return '$value/session';
  }

  static String _formatDistance(double? meters, double? kmValue) {
    if (meters != null) {
      if (meters < 1000) return '${meters.round()}m';
      final km = meters / 1000;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)}km';
    }
    if (kmValue == null) return '';
    if (kmValue < 1) return '${(kmValue * 1000).round()}m';
    return '${kmValue.toStringAsFixed(kmValue >= 10 ? 0 : 1)}km';
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
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }

  static const List<String> _imageKeys = [
    'image',
    'imageUrl',
    'image_url',
    'profileImage',
    'profileImageUrl',
    'profile_image',
    'profile_image_url',
    'profilePicture',
    'profilePictureUrl',
    'profile_picture',
    'profile_picture_url',
    'photo',
    'photoUrl',
    'photo_url',
    'avatar',
    'avatarUrl',
    'avatar_url',
    'url',
    'secureUrl',
    'secure_url',
    'path',
    'fileUrl',
    'file_url',
  ];

  static const List<String> _imageObjectKeys = [
    'image',
    'profileImage',
    'profileImageUrl',
    'profile_image',
    'profile_image_url',
    'profilePicture',
    'profilePictureUrl',
    'profile_picture',
    'profile_picture_url',
    'photo',
    'avatar',
  ];

  static String? _readImageUrl(
    Map<String, dynamic> source,
    Map<String, dynamic> profile,
  ) {
    final directValue =
        _readString(source, _imageKeys) ?? _readString(profile, _imageKeys);
    final nestedValue =
        _readNestedImageUrl(source) ?? _readNestedImageUrl(profile);

    return normalizeImageUrl(directValue ?? nestedValue);
  }

  static String? _readNestedImageUrl(Map<String, dynamic> json) {
    for (final key in _imageObjectKeys) {
      final image = _object(json[key]);
      if (image == null) continue;

      final value = _readString(image, _imageKeys);
      if (value != null) return value;
    }

    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) return null;

    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) return null;

    return double.tryParse(value);
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys)?.toLowerCase();
    if (value == null) return null;
    if (value == 'true' || value == '1' || value == 'yes') return true;
    if (value == 'false' || value == '0' || value == 'no') return false;
    return null;
  }
}
