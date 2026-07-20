import 'package:fitness/utils/auth_role.dart';
import 'package:fitness/utils/image_url.dart';

class UserProfileModel {
  final String? id;
  final String? trainerUserId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final String? role;
  final String? imageUrl;
  final String? state;
  final String? location;
  final String? bio;
  final String? accountStatus;
  final int? age;
  final double? weight;
  final String? weightUnit;
  final String? dietPreference;
  final String? coverPhotoUrl;

  // ── Trainer-specific fields ──────────────────────────────────────────────
  final List<String>? fitnessClasses;
  final String? instructorDuration;
  final String? certifications;
  final String? sessionFormat;
  final double? baseLocationLat;
  final double? baseLocationLng;

  // ── Trainer payout (Stripe Connect) ──────────────────────────────────────
  final String? stripeConnectAccountId;
  final bool? stripeConnectOnboardingComplete;
  final bool? stripeChargesEnabled;
  final bool? stripePayoutsEnabled;
  final bool? stripeDetailsSubmitted;
  final String? stripeConnectUpdatedAt;
  final bool? payoutReady;

  const UserProfileModel({
    this.id,
    this.trainerUserId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.role,
    this.imageUrl,
    this.state,
    this.location,
    this.bio,
    this.accountStatus,
    this.age,
    this.weight,
    this.weightUnit,
    this.dietPreference,
    this.coverPhotoUrl,
    this.fitnessClasses,
    this.instructorDuration,
    this.certifications,
    this.sessionFormat,
    this.baseLocationLat,
    this.baseLocationLng,
    this.stripeConnectAccountId,
    this.stripeConnectOnboardingComplete,
    this.stripeChargesEnabled,
    this.stripePayoutsEnabled,
    this.stripeDetailsSubmitted,
    this.stripeConnectUpdatedAt,
    this.payoutReady,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final source = _object(data['user']) ?? data;
    final profile =
        _object(data['profile']) ??
        _object(data['memberProfile']) ??
        _object(data['member_profile']) ??
        _object(data['trainerProfile']) ??
        _object(data['trainer_profile']) ??
        _object(source['profile']) ??
        _object(source['memberProfile']) ??
        _object(source['member_profile']) ??
        _object(source['trainerProfile']) ??
        _object(source['trainer_profile']) ??
        const <String, dynamic>{};

    final firstName = _readString(source, const ['firstName', 'first_name']);
    final lastName = _readString(source, const ['lastName', 'last_name']);
    final combinedName = [
      firstName,
      lastName,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    return UserProfileModel(
      id: _readString(source, const ['id', 'userId', 'user_id']),
      trainerUserId:
          _readString(profile, const [
            'trainerUserId',
            'trainer_user_id',
            'userId',
            'user_id',
          ]) ??
          _readString(data, const ['trainerUserId', 'trainer_user_id']),
      firstName: firstName,
      lastName: lastName,
      fullName:
          _readString(source, const [
            'name',
            'displayName',
            'display_name',
            'fullName',
            'full_name',
          ]) ??
          (combinedName.isEmpty ? null : combinedName),
      email: _readString(source, const ['email']),
      phoneNumber: _readString(source, const [
        'phoneNumber',
        'phone_number',
        'phone',
      ]),
      gender: _readString(source, const ['gender']),
      role: normalizeUserRole(data) ?? normalizeUserRole(source),
      imageUrl: _readImageUrl(source, profile),
      state:
          _readString(source, const ['state']) ??
          _readString(profile, const ['state']),
      location:
          _readString(source, const ['location', 'address']) ??
          _readString(profile, const ['location', 'address']),
      bio:
          _readString(source, const ['bio', 'description']) ??
          _readString(profile, const ['bio', 'description']),
      accountStatus:
          _readString(source, const [
            'accountStatus',
            'account_status',
            'approvalStatus',
            'approval_status',
            'status',
          ]) ??
          _readString(profile, const [
            'accountStatus',
            'account_status',
            'approvalStatus',
            'approval_status',
            'status',
          ]),
      age: _readInt(source, const ['age']) ?? _readInt(profile, const ['age']),
      weight:
          _readDouble(source, const ['weight']) ??
          _readDouble(profile, const ['weight']),
      weightUnit:
          _readString(source, const ['weightUnit', 'weight_unit']) ??
          _readString(profile, const ['weightUnit', 'weight_unit']),
      dietPreference:
          _readString(source, const ['dietPreference', 'diet_preference']) ??
          _readString(profile, const ['dietPreference', 'diet_preference']),
      coverPhotoUrl: _normalizeCoverUrl(
        _readString(source, const [
              'coverPhotoUrl',
              'cover_photo_url',
              'coverPhoto',
            ]) ??
            _readString(profile, const [
              'coverPhotoUrl',
              'cover_photo_url',
              'coverPhoto',
            ]),
      ),
      fitnessClasses:
          _readStringList(source, const [
            'fitnessClasses',
            'fitness_classes',
          ]) ??
          _readStringList(profile, const ['fitnessClasses', 'fitness_classes']),
      instructorDuration:
          _readString(source, const [
            'instructorDuration',
            'instructor_duration',
          ]) ??
          _readString(profile, const [
            'instructorDuration',
            'instructor_duration',
          ]),
      certifications:
          _readString(source, const ['certifications']) ??
          _readString(profile, const ['certifications']),
      sessionFormat:
          _readString(source, const ['sessionFormat', 'session_format']) ??
          _readString(profile, const ['sessionFormat', 'session_format']),
      baseLocationLat:
          _readDouble(source, const [
            'baseLocationLat',
            'base_location_lat',
            'baseLatitude',
            'base_latitude',
          ]) ??
          _readDouble(profile, const [
            'baseLocationLat',
            'base_location_lat',
            'baseLatitude',
            'base_latitude',
          ]),
      baseLocationLng:
          _readDouble(source, const [
            'baseLocationLng',
            'base_location_lng',
            'baseLongitude',
            'base_longitude',
          ]) ??
          _readDouble(profile, const [
            'baseLocationLng',
            'base_location_lng',
            'baseLongitude',
            'base_longitude',
          ]),
      stripeConnectAccountId: _readString(source, const [
        'stripeConnectAccountId',
        'stripe_connect_account_id',
      ]),
      stripeConnectOnboardingComplete: _readBool(source, const [
        'stripeConnectOnboardingComplete',
        'stripe_connect_onboarding_complete',
      ]),
      stripeChargesEnabled: _readBool(source, const [
        'stripeChargesEnabled',
        'stripe_charges_enabled',
      ]),
      stripePayoutsEnabled: _readBool(source, const [
        'stripePayoutsEnabled',
        'stripe_payouts_enabled',
      ]),
      stripeDetailsSubmitted: _readBool(source, const [
        'stripeDetailsSubmitted',
        'stripe_details_submitted',
      ]),
      stripeConnectUpdatedAt: _readString(source, const [
        'stripeConnectUpdatedAt',
        'stripe_connect_updated_at',
      ]),
      payoutReady: _readBool(source, const ['payoutReady', 'payout_ready']),
    );
  }

  String get displayName {
    final value = fullName?.trim();
    if (value != null && value.isNotEmpty) return value;

    final combinedName = [
      firstName,
      lastName,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    if (combinedName.isNotEmpty) return combinedName;

    final emailValue = email?.trim();
    if (emailValue != null && emailValue.isNotEmpty) {
      return emailValue.split('@').first;
    }

    final roleValue = role?.trim().toLowerCase();
    if (roleValue == 'member') return 'Member';
    if (roleValue == 'admin') return 'Admin';

    return 'Trainer';
  }

  String get displayLocation {
    final locationValue = location?.trim();
    if (locationValue != null && locationValue.isNotEmpty) {
      return locationValue;
    }

    final stateValue = state?.trim();
    if (stateValue != null && stateValue.isNotEmpty) {
      return stateValue;
    }

    return 'Location not added';
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

  static List<String>? _readStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is List) {
        final list = value
            .where((e) => e != null)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
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
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }

  static String? _normalizeCoverUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return normalizeImageUrl(url);
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
}
