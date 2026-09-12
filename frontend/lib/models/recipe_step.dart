class RecipeStep {
  const RecipeStep({
    required this.id,
    required this.sectionTitle,
    required this.title,
    required this.description,
    required this.contentType,
    this.mediaUrl,
    this.durationSeconds,
  });

  final String id;
  final String sectionTitle;
  final String title;
  final String description;
  final String contentType;
  final String? mediaUrl;
  final int? durationSeconds;

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    required String sectionTitle,
    required String sectionDescription,
  }) {
    return RecipeStep(
      id: json['id'] as String? ?? '',
      sectionTitle: sectionTitle,
      title: json['title'] as String? ?? sectionTitle,
      description: json['textContent'] as String? ?? sectionDescription,
      contentType: json['contentType'] as String? ?? 'text',
      mediaUrl: json['mediaUrl'] as String?,
      durationSeconds: _toInt(json['durationSeconds']),
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }
}
