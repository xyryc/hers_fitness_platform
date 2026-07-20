import 'package:fitness/utils/auth_role.dart';
import 'package:fitness/utils/image_url.dart';

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel? user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    return AuthResponseModel(
      accessToken:
          (data['access_token'] ?? data['accessToken'] ?? data['token'] ?? '')
              .toString(),
      refreshToken: (data['refresh_token'] ?? data['refreshToken'])?.toString(),
      user: UserModel.fromJson(userJson),
    );
  }
}

class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? imageUrl;

  const UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName'] ?? json['first_name'];
    final lastName = json['lastName'] ?? json['last_name'];
    final combinedName = [firstName, lastName]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' ');

    return UserModel(
      id: int.tryParse((json['id'] ?? '').toString()),
      name:
          (json['name'] ??
                  json['displayName'] ??
                  json['display_name'] ??
                  json['fullName'] ??
                  json['full_name'] ??
                  combinedName)
              .toString()
              .trim(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['phone_number'])
          ?.toString(),
      role: normalizeUserRole(json),
      imageUrl: normalizeImageUrl(
        (json['image'] ??
                json['imageUrl'] ??
                json['image_url'] ??
                json['profileImage'] ??
                json['profileImageUrl'] ??
                json['profile_image'] ??
                json['profile_image_url'] ??
                json['avatar'] ??
                json['avatarUrl'] ??
                json['avatar_url'])
            ?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'image_url': imageUrl,
    };
  }
}
