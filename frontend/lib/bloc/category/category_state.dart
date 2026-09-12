import 'package:flutter_application_1/models/category.dart';

abstract class CategoryState {
  CategoryState();
  // id หมวดที่เลือกอยู่ ค่าว่าง = ไม่ได้กรอง (มีค่าจริงเฉพาะตอน CategoryLoaded)
  String get selectedId => '';
}

class CategoryInitial extends CategoryState {
  CategoryInitial();
}

class CategoryLoading extends CategoryState {
  CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  @override
  final String selectedId;
  CategoryLoaded(this.categories, {this.selectedId = ''});
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError({required this.message});
}