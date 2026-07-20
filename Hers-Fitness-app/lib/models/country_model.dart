class CountryModel {
  final String? id;
  final String name;
  final String? code;
  final String? codeIso3;
  final String? dialCode;
  final Map<String, dynamic> raw;

  const CountryModel({
    this.id,
    required this.name,
    this.code,
    this.codeIso3,
    this.dialCode,
    this.raw = const <String, dynamic>{},
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final dataRoot = _object(json['data']) ?? json;
    final data = _object(dataRoot['country']) ?? dataRoot;

    return CountryModel(
      id: _readString(data, const ['id']),
      name:
          _readString(data, const ['name', 'countryName', 'country_name']) ??
          'Country',
      code: _readString(data, const ['code', 'codeIso2', 'code_iso2']),
      codeIso3: _readString(data, const ['codeIso3', 'code_iso3', 'iso3']),
      dialCode: _readString(data, const [
        'dialCode',
        'dial_code',
        'phoneCode',
        'phone_code',
      ]),
      raw: data,
    );
  }

  static List<CountryModel> listFromResponse(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map(_stringMap)
          .map(CountryModel.fromJson)
          .toList();
    }

    if (response is Map) {
      final map = _stringMap(response);
      for (final key in const ['countries', 'items', 'results']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map(_stringMap)
              .map(CountryModel.fromJson)
              .toList();
        }
      }

      final data = map['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(_stringMap)
            .map(CountryModel.fromJson)
            .toList();
      }
      if (data is Map) {
        return listFromResponse(data);
      }
    }

    return const <CountryModel>[];
  }
}

Map<String, dynamic>? _object(dynamic value) {
  if (value is Map) return _stringMap(value);
  return null;
}

Map<String, dynamic> _stringMap(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String? _readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;

  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }

  return null;
}
