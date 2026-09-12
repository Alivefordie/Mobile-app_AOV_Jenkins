import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:http/http.dart' as http;

class FoodRepository {
  static const String baseUrl = 'http://10.0.2.2:3000';
  //static const String baseUrl = 'http://localhost:3000';

  // =========================== เรียกใช้ตรงนี้ ==================================

  Future<List<Food>> fetchFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId';
    return _getFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchCommunityFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId?type=community';
    return _getFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchOfficialFoodsByCategoryId(String categoryId) async {
    final url = '$baseUrl/categories/$categoryId?type=official';
    return _getFoodsByCategoryId(url);
  }

  // ================================

  Future<List<Food>> fetchCommuityAllFoodsByCategoryId() async {
    final url = '$baseUrl/categories?type=community';
    return _getAllFoodsByCategoryId(url);
  }

  Future<List<Food>> fetchOfficialAllFoodsByCategoryId() async {
    final url = '$baseUrl/categories?type=official';
    return _getAllFoodsByCategoryId(url);
  }

  // ================================

  Future<List<Food>> fetchFoods() async {
    return _getFoods('$baseUrl/recipes');
  }

  Future<List<Food>> fetchCommunityFoods() async {
    return _getFoods('$baseUrl/recipes?type=community');
  }

  Future<List<Food>> fetchOfficialFoods() async {
    return _getFoods('$baseUrl/recipes?type=official');
  }

  // ================================

  Future<Food> fetchFoodById(String id) async {
    final url = '$baseUrl/recipes/$id';
    return _getFoodById(url);
  }

  // ============================ อ่านฟังก์ชั่น ==============================

  Future<List<Food>> _getAllFoodsByCategoryId(String url) async {
    debugPrint('Fetching from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> categories = json.decode(response.body);
      final foods = <Food>[];
      for (final cat in categories) {
        final recipes = (cat as Map<String, dynamic>)['recipes'] as List<dynamic>? ?? [];
        foods.addAll(recipes.map((r) => Food.fromJson(r as Map<String, dynamic>)));
      }
      return foods;
    } else {
      throw Exception('Failed to load foods');
    }
  }

  Future<List<Food>> _getFoodsByCategoryId(String url) async {
    debugPrint('Fetching foods by category from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final category = json.decode(response.body) as Map<String, dynamic>;
      final recipes = category['recipes'] as List<dynamic>? ?? [];
      final foods = recipes
          .map((json) => Food.fromJson(json as Map<String, dynamic>))
          .toList();
      // debugPrint(
      //   'Parsed ${foods.length} foods in category ${category['name']}',
      // );
      return foods;
      
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบหมวดหมู่นี้');
    } else {
      debugPrint('Failed to load category: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }

  Future<Food> _getFoodById(String url) async {
    debugPrint('Fetching food from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final food = Food.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      debugPrint('Parsed food: ${food.idfoods} - ${food.name}');
      return food;
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบเมนูนี้');
    } else {
      debugPrint('Failed to load food: ${response.statusCode}');
      throw Exception('Failed to load food');
    }
  }

  Future<List<Food>> _getFoods(String url) async {
    debugPrint('Fetching foods from: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final foods = jsonList.map((json) => Food.fromJson(json)).toList();
      // debugPrint('Parsed ${foods.length} foods successfully');
      // for (var food in foods) {
      //   debugPrint('  - ${food.idfoods}: ${food.name} (${food.category})');
      // }
      return foods;
    } else {
      debugPrint('Failed to load foods: ${response.statusCode}');
      throw Exception('Failed to load foods');
    }
  }
  // =====================================================================
}