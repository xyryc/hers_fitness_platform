class StaticContentModel {
  final String key;
  final String title;
  final String content;
  final DateTime? updatedAt;

  const StaticContentModel({
    required this.key,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  factory StaticContentModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return StaticContentModel(
      key: data['key']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
    );
  }
}
