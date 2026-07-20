import 'package:http/http.dart' as http;

class MemberRegisterPayload {
  final String name;
  final String email;
  final String phoneNumber;
  final String state;
  final String location;
  final String? timezone;
  final String idCardType;
  final String idCardNumber;
  final String password;
  final String confirmPassword;
  final String imagePath;
  final String idCardFrontImagePath;
  final String idCardBackImagePath;

  const MemberRegisterPayload({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.state,
    required this.location,
    this.timezone,
    required this.idCardType,
    required this.idCardNumber,
    required this.password,
    required this.confirmPassword,
    required this.imagePath,
    required this.idCardFrontImagePath,
    required this.idCardBackImagePath,
  });

  Map<String, String> get fields {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'state': state,
      'location': location,
      if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone!,
      'idCardType': idCardType,
      'idCardNumber': idCardNumber,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }

  Future<List<http.MultipartFile>> toMultipartFiles() async {
    return [
      await http.MultipartFile.fromPath('image', imagePath),
      await http.MultipartFile.fromPath(
        'idCardFrontImage',
        idCardFrontImagePath,
      ),
      await http.MultipartFile.fromPath('idCardBackImage', idCardBackImagePath),
    ];
  }
}
