class TrainerTopClassModel {
  final String id;
  final String name;
  final String classType;
  final String sessionFormat;
  final int bookingCount;
  final double totalRevenue;

  const TrainerTopClassModel({
    required this.id,
    required this.name,
    required this.classType,
    required this.sessionFormat,
    required this.bookingCount,
    required this.totalRevenue,
  });

  factory TrainerTopClassModel.fromJson(Map<String, dynamic> json) {
    return TrainerTopClassModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      classType: json['classType']?.toString() ?? '',
      sessionFormat: json['sessionFormat']?.toString() ?? '',
      bookingCount: int.tryParse(json['bookingCount']?.toString() ?? '0') ?? 0,
      totalRevenue:
          double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0,
    );
  }

  String get displayClassType {
    switch (classType.toUpperCase()) {
      case 'IN_PERSON':
        return 'In Person';
      case 'ONLINE':
        return 'Online';
      default:
        return classType;
    }
  }

  String get displaySessionFormat {
    switch (sessionFormat.toUpperCase()) {
      case 'PRIVATE':
        return 'One-to-one';
      case 'GROUP':
        return 'Group';
      default:
        return sessionFormat;
    }
  }
}
