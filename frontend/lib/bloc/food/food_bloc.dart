import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;

  FoodBloc(this.repository) : super(FoodInitial()) {
    on<FetchFoodEvent>(_onFetchFoodEvent);
    on<FetchFoodByCategoryEvent>(_onFetchFoodByCategoryEvent);
    on<FetchCommunityFoodsByCategoryEvent>(_onFetchCommunityFoodsByCategoryEvent);
  }


  Future<void> _onFetchFoodEvent(
    FetchFoodEvent event,
    Emitter<FoodState> emit) async {
    emit(FoodLoading());
    try {
      final foods = await repository.fetchFoods();
      emit(FoodLoaded(foods));
    } catch (e) {
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onFetchFoodByCategoryEvent(
    FetchFoodByCategoryEvent event,
    Emitter<FoodState> emit) async {
    emit(FoodLoading());
    try {
      // ถ้าไม่ได้เลือก category ให้ดึงทั้งหมด กดซ้ำเพื่อยกเลิก
      final foods = event.categoryId.isEmpty
          //? await repository.fetchFoods()
          ? await repository.fetchOfficialAllFoodsByCategoryId()
          : await repository.fetchOfficialFoodsByCategoryId(event.categoryId);
      emit(FoodLoaded(foods));
    } catch (e) {
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onFetchCommunityFoodsByCategoryEvent(
    FetchCommunityFoodsByCategoryEvent event,
    Emitter<FoodState> emit) async {
    emit(FoodLoading());
    try {
      // ถ้าไม่ได้เลือก category ให้ดึงทั้งหมด กดซ้ำเพื่อยกเลิก
      final foods = event.categoryId.isEmpty
          //? await repository.fetchFoods()
          ? await repository.fetchCommuityAllFoodsByCategoryId()
          : await repository.fetchCommunityFoodsByCategoryId(event.categoryId);
      emit(FoodLoaded(foods));
    } catch (e) {
      emit(FoodError(message: e.toString()));
    }
  }
}