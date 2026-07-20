import 'package:http/http.dart' as http;

class IdentityVerificationPayload {
  final String role;
  final String documentType;
  final String frontImagePath;
  final String backImagePath;

  const IdentityVerificationPayload({
    required this.role,
    required this.documentType,
    required this.frontImagePath,
    required this.backImagePath,
  });

  Map<String, String> get fields {
    return {'role': role, 'document_type': documentType};
  }

  Map<String, String> toJson() {
    return {
      ...fields,
      'front_image_path': frontImagePath,
      'back_image_path': backImagePath,
    };
  }

  Future<List<http.MultipartFile>> toMultipartFiles() async {
    return [
      await http.MultipartFile.fromPath('front_image', frontImagePath),
      await http.MultipartFile.fromPath('back_image', backImagePath),
    ];
  }
}
