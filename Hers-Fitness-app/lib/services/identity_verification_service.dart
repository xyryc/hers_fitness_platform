import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/identity_verification_payload.dart';

class IdentityVerificationService {
  IdentityVerificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<dynamic> submit(IdentityVerificationPayload payload) async {
    return _apiClient.multipartPost(
      endpoint: ApiEndpoints.identityVerification,
      fields: payload.fields,
      files: await payload.toMultipartFiles(),
    );
  }
}
