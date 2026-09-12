import 'dart:convert';
// foundation ก็ export ชื่อ Category (annotation) มาด้วย เลยต้อง hide ไว้
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_application_1/models/category.dart';
import 'package:http/http.dart' as http;

class CategoryRepository {
  // Base URL for the API
  static const String baseUrl = 'http://10.0.2.2:3000';
  //static const String baseUrl = 'http://localhost:3000';

  Future<List<Category>> fetchCategories() async {
    final url = '$baseUrl/categories';
    debugPrint('Fetching categories from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final categories = jsonList.map((json) => Category.fromJson(json)).toList();

      debugPrint('Parsed ${categories.length} categories successfully');
      for (var category in categories) {
        debugPrint('  - ${category.slug}: ${category.name}');
      }

      return categories;
    } else {
      debugPrint('Failed to load categories: ${response.statusCode}');
      throw Exception('Failed to load categories');
    }
  }
}
