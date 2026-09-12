import 'package:flutter_application_1/models/food.dart';

abstract class FoodState {
  FoodState();
}

class FoodInitial extends FoodState {
  //Constructor
  FoodInitial();
}

class FoodLoading extends FoodState {
  //Constructor
  FoodLoading();
}

class FoodLoaded extends FoodState {
  final List<Food> foods;
  // คำค้นหาที่ทำให้ได้ผลลัพธ์ชุดนี้ ถ้าเป็น null คือไม่ได้มาจากการค้นหา
  final String? query;
  FoodLoaded(this.foods, {this.query});
}

class FoodError extends FoodState {
  final String message;
  FoodError({required this.message});
}
