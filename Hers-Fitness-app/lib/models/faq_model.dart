class FaqModel {
  final String id;
  final String question;
  final String answer;
  final int order;

  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      order: int.tryParse(json['order']?.toString() ?? '') ?? 0,
    );
  }

  /// Whether this FAQ matches [query] (case-insensitive, searches both fields)
  bool matches(String query) {
    final q = query.toLowerCase();
    return question.toLowerCase().contains(q) ||
        answer.toLowerCase().contains(q);
  }
}
