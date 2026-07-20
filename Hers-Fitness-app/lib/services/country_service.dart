import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/country_model.dart';

class CountryService {
  CountryService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<CountryModel>> getCountries() async {
    final response = await _apiClient.get(ApiEndpoints.countries);
    return CountryModel.listFromResponse(response);
  }

  Future<CountryModel> getCountryByIso3(String codeIso3) async {
    final response = await _apiClient.get(ApiEndpoints.countryByIso3(codeIso3));
    return CountryModel.fromJson(_asMap(response));
  }

  Future<CountryModel> getCountryByCode(String code) async {
    final response = await _apiClient.get(ApiEndpoints.countryByCode(code));
    return CountryModel.fromJson(_asMap(response));
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const ApiException('Invalid server response');
  }
}
