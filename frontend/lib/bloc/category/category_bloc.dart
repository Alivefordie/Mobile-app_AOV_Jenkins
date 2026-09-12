import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc(this.repository) : super(CategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategoriesEvent);
    on<CategorySelectEvent>(_onCategorySelectEvent);
  }

  Future<void> _onFetchCategoriesEvent(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await repository.fetchCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  void _onCategorySelectEvent(
    CategorySelectEvent event,
    Emitter<CategoryState> emit,
  ) {
    final current = state;
    if (current is! CategoryLoaded) return;

    // กดอันเดิมซ้ำ = ยกเลิกการกรอง
    final selected = current.selectedId == event.id ? '' : event.id;
    emit(CategoryLoaded(current.categories, selectedId: selected));
  }
}
