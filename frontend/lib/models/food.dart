import 'package:flutter_application_1/models/recipe_step.dart';

class Food {
  final String idfoods;
  final String name;
  final String category;
  final String description;
  final String filePathImage;

  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? servingCount;
  final String? difficulty;
  final List<RecipeStep> steps;

  Food({
    required this.idfoods,
    required this.name,
    required this.category,
    required this.description,
    required this.filePathImage,
    this.preparationMinutes,
    this.cookingMinutes,
    this.servingCount,
    this.difficulty,
    this.steps = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    // recipe หนึ่งอันมีได้หลาย category ที่นี่ใช้อันแรกมาโชว์บนการ์ด
    final categories = json['categories'] as List<dynamic>?;
    final firstCategory = (categories != null && categories.isNotEmpty)
        ? categories.first as Map<String, dynamic>
        : null;

    final sections = json['sections'] as List<dynamic>? ?? const [];
    final steps = <RecipeStep>[];
    for (final sectionValue in sections) {
      if (sectionValue is! Map<String, dynamic>) continue;
      final sectionTitle = sectionValue['title'] as String? ?? 'ขั้นตอน';
      final sectionDescription = sectionValue['description'] as String? ?? '';
      final contents = sectionValue['contents'] as List<dynamic>? ?? const [];

      for (final contentValue in contents) {
        if (contentValue is! Map<String, dynamic>) continue;
        steps.add(
          RecipeStep.fromJson(
            contentValue,
            sectionTitle: sectionTitle,
            sectionDescription: sectionDescription,
          ),
        );
      }
    }

    return Food(
      idfoods: json['id'] as String,
      name: json['title'] as String,
      category: firstCategory?['name'] as String? ?? '',
      description: json['shortDescription'] as String? ?? '',
      filePathImage: json['coverImageUrl'] as String? ?? '',
      preparationMinutes: _toInt(json['preparationMinutes']),
      cookingMinutes: _toInt(json['cookingMinutes']),
      servingCount: _toInt(json['servingCount']),
      difficulty: json['difficulty'] as String?,
      steps: steps,
    );
  }

  // numeric ที่ส่งมาจาก API อาจมาเป็น int หรือ String ก็ได้
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
