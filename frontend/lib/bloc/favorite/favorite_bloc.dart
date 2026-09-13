import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_state.dart';
import 'package:flutter_application_1/repositories/favorite_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// อ่าน token จาก secure storage เองทุกครั้งแบบเดียวกับ ProfileBloc
/// storage ไม่มี stream บอกว่าค่าเปลี่ยน หน้า login/logout จึงต้องสั่ง
/// FavoritesRequested เองหลังเขียน/ลบ token
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const FavoriteState()) {
    on<FavoritesRequested>(_onRequested);
    on<FavoriteToggled>(_onToggled);
  }

  final FavoriteRepository _repository;
  final TokenStorage _tokenStorage;

  Future<String?> _readAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return null;
    return accessToken;
  }

  Future<void> _onRequested(
    FavoritesRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    final accessToken = await _readAccessToken();

    // ยังไม่ล็อกอิน หรือเพิ่ง logout หัวใจของคนก่อนหน้าต้องไม่ค้างบนการ์ด
    if (accessToken == null) {
      emit(const FavoriteState(status: FavoriteStatus.ready));
      return;
    }

    // เริ่มจาก state เปล่าเสมอ กันหัวใจของบัญชีก่อนหน้าติดมา
    emit(const FavoriteState(status: FavoriteStatus.loading));

    try {
      final recipeIds = await _repository.fetchFavoriteRecipeIds(accessToken);
      emit(
        FavoriteState(status: FavoriteStatus.ready, recipeIds: recipeIds),
      );
    } on Exception catch (error) {
      emit(
        FavoriteState(
          status: FavoriteStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onToggled(
    FavoriteToggled event,
    Emitter<FavoriteState> emit,
  ) async {
    final accessToken = await _readAccessToken();
    if (accessToken == null) return;

    final recipeId = event.recipeId;
    // กำลังยิงอยู่แล้ว กดซ้ำระหว่างรอไม่ต้องทำอะไร
    if (state.isPending(recipeId)) return;

    final wasFavorite = state.isFavorite(recipeId);
    final nextIds = {...state.recipeIds};
    wasFavorite ? nextIds.remove(recipeId) : nextIds.add(recipeId);

    // สลับหัวใจให้ทันทีแล้วค่อยยิง API ถ้าพลาดค่อยย้อนกลับ
    emit(
      state.copyWith(
        status: FavoriteStatus.ready,
        recipeIds: nextIds,
        pendingRecipeIds: {...state.pendingRecipeIds, recipeId},
        clearError: true,
      ),
    );

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(accessToken, recipeId);
      } else {
        await _repository.addFavorite(accessToken, recipeId);
      }
      emit(state.copyWith(pendingRecipeIds: _without(recipeId)));
    } on Exception catch (error) {
      final revertedIds = {...state.recipeIds};
      wasFavorite ? revertedIds.add(recipeId) : revertedIds.remove(recipeId);

      emit(
        state.copyWith(
          status: FavoriteStatus.failure,
          recipeIds: revertedIds,
          pendingRecipeIds: _without(recipeId),
          error: error.toString(),
        ),
      );
    }
  }

  Set<String> _without(String recipeId) =>
      {...state.pendingRecipeIds}..remove(recipeId);
}
