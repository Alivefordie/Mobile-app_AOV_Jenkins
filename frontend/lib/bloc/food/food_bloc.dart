import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;

  //system search
  // กันผลลัพธ์ของ request เก่ามาทับ request ล่าสุด
  // เช่น ผู้ใช้พิมพ์ค้นหาแล้วกดล้างทันที ทั้งสอง request วิ่งพร้อมกัน
  int _requestId = 0;

  FoodBloc(this.repository) : super(FoodInitial()) {
    on<FetchFoodEvent>(_onFetchFoodEvent);
    on<FetchFoodByCategoryEvent>(_onFetchFoodByCategoryEvent);
    on<FetchCommunityFoodsByCategoryEvent>(_onFetchCommunityFoodsByCategoryEvent);
    on<SearchFoodEvent>(_onSearchFoodEvent);
  }


  Future<void> _onFetchFoodEvent(
    FetchFoodEvent event,
    Emitter<FoodState> emit) async {
    final requestId = ++_requestId;
    emit(FoodLoading());
    try {
      final foods = await repository.fetchFoods();
      if (requestId != _requestId) return;
      emit(FoodLoaded(foods));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onFetchFoodByCategoryEvent(
    FetchFoodByCategoryEvent event,
    Emitter<FoodState> emit) async {
    final requestId = ++_requestId;
    emit(FoodLoading());
    try {
      // ถ้าไม่ได้เลือก category ให้ดึงทั้งหมด กดซ้ำเพื่อยกเลิก
      final foods = event.categoryId.isEmpty
          //? await repository.fetchFoods()
          ? await repository.fetchOfficialAllFoodsByCategoryId()
          : await repository.fetchOfficialFoodsByCategoryId(event.categoryId);
      if (requestId != _requestId) return;
      emit(FoodLoaded(foods));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onFetchCommunityFoodsByCategoryEvent(
    FetchCommunityFoodsByCategoryEvent event,
    Emitter<FoodState> emit) async {
    final requestId = ++_requestId;
    emit(FoodLoading());
    try {
      // ถ้าไม่ได้เลือก category ให้ดึงทั้งหมด กดซ้ำเพื่อยกเลิก
      final foods = event.categoryId.isEmpty
          //? await repository.fetchFoods()
          ? await repository.fetchCommuityAllFoodsByCategoryId()
          : await repository.fetchCommunityFoodsByCategoryId(event.categoryId);
      if (requestId != _requestId) return;
      emit(FoodLoaded(foods));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onSearchFoodEvent(
    SearchFoodEvent event,
    Emitter<FoodState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    final requestId = ++_requestId;
    emit(FoodLoading());
    try {
      // หน้า home แสดงเฉพาะสูตร official จึงค้นหาในขอบเขตเดียวกัน
      // และถ้าเลือกหมวดอยู่ ต้องค้นหาเฉพาะในหมวดนั้น
      final foods = await repository.searchFoods(
        query,
        type: 'official',
        categoryId: event.categoryId.isEmpty ? null : event.categoryId,
      );
      if (requestId != _requestId) return;
      emit(FoodLoaded(foods, query: query));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FoodError(message: e.toString()));
    }
  }
}
