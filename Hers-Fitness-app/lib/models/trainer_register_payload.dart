import 'package:http/http.dart' as http;

class TrainerRegisterPayload {
  final String name;
  final String email;
  final String phoneNumber;
  final String state;
  final String location;
  final String? timezone;
  final String idCardType;
  final String idCardNumber;
  final String bio;
  final String classesTaught;
  final String instructorExperience;
  final String certifications;
  final String classDeliveryMode;
  final String password;
  final String confirmPassword;
  final String imagePath;
  final String idCardFrontImagePath;
  final String idCardBackImagePath;

  const TrainerRegisterPayload({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.state,
    required this.location,
    this.timezone,
    required this.idCardType,
    required this.idCardNumber,
    required this.bio,
    required this.classesTaught,
    required this.instructorExperience,
    required this.certifications,
    required this.classDeliveryMode,
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
      'bio': bio,
      'classesTaught': classesTaught,
      'instructorExperience': instructorExperience,
      'certifications': certifications,
      'classDeliveryMode': classDeliveryMode,
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
