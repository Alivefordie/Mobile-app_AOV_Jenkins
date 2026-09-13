import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/repositories/cart_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// อ่าน token จาก secure storage เองทุกครั้งแบบเดียวกับ ProfileBloc
/// storage ไม่มี stream บอกว่าค่าเปลี่ยน หน้า login/logout จึงต้องสั่ง
/// CartRequested เองหลังเขียน/ลบ token
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const CartState()) {
    on<CartRequested>(_onRequested);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
  }

  final CartRepository _repository;
  final TokenStorage _tokenStorage;

  Future<String?> _readAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return null;
    return accessToken;
  }

  Future<void> _onRequested(
    CartRequested event,
    Emitter<CartState> emit,
  ) async {
    final accessToken = await _readAccessToken();

    // ยังไม่ล็อกอิน หรือเพิ่ง logout ตะกร้าของคนก่อนหน้าต้องไม่ค้าง
    if (accessToken == null) {
      emit(const CartState(status: CartStatus.ready));
      return;
    }

    // เริ่มจาก state เปล่าเสมอ ไม่ใช่ copyWith
    // เพราะถ้าสลับบัญชี cartId ของคนเก่าจะติดมาด้วย
    emit(const CartState(status: CartStatus.loading));

    try {
      final cartId = await _repository.findCartId(accessToken);
      // ยังไม่เคยกดเพิ่มของ = ยังไม่มีตะกร้า ถือว่าตะกร้าว่าง
      if (cartId == null) {
        emit(const CartState(status: CartStatus.ready));
        return;
      }

      final items = await _repository.fetchItems(accessToken, cartId);
      emit(CartState(status: CartStatus.ready, cartId: cartId, items: items));
    } on Exception catch (error) {
      emit(
        CartState(status: CartStatus.failure, error: error.toString()),
      );
    }
  }

  Future<void> _onItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    final accessToken = await _readAccessToken();
    if (accessToken == null) return;

    final food = event.food;
    final recipeId = food.idfoods;

    if (state.isPending(recipeId)) return;

    // อยู่ในตะกร้าแล้วไม่เพิ่มซ้ำ แค่บอกผู้ใช้ว่ามีอยู่แล้ว
    if (state.contains(recipeId)) {
      emit(
        state.copyWith(
          feedback: CartFeedback.alreadyInCart,
          feedbackTitle: food.name,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        pendingRecipeIds: {...state.pendingRecipeIds, recipeId},
        clearError: true,
      ),
    );

    try {
      // ตะกร้าเกิดตอนนี้ถ้ายังไม่มี แล้วค่อยเพิ่มของลงไป
      final cartId =
          state.cartId ?? await _repository.createCart(accessToken);
      await _repository.addItem(accessToken, cartId, recipeId);
      // ดึงใหม่ทั้งชุดเพื่อให้ชื่อ รูป ราคา ตรงกับที่ join มาจาก recipe
      final items = await _repository.fetchItems(accessToken, cartId);

      emit(
        state.copyWith(
          status: CartStatus.ready,
          cartId: cartId,
          items: items,
          pendingRecipeIds: _without(recipeId),
          feedback: CartFeedback.added,
          feedbackTitle: food.name,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: CartStatus.failure,
          pendingRecipeIds: _without(recipeId),
          feedback: CartFeedback.failed,
          feedbackTitle: food.name,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    final cartId = state.cartId;
    if (cartId == null) return;

    final accessToken = await _readAccessToken();
    if (accessToken == null) return;

    try {
      await _repository.removeItem(accessToken, cartId, event.itemId);
      final items = state.items
          .where((item) => item.id != event.itemId)
          .toList(growable: false);

      emit(
        state.copyWith(
          status: CartStatus.ready,
          items: items,
          clearError: true,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(status: CartStatus.failure, error: error.toString()),
      );
    }
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    final cartId = state.cartId;
    if (cartId == null) return;

    final accessToken = await _readAccessToken();
    if (accessToken == null) return;

    try {
      await _repository.clearItems(accessToken, cartId);
      emit(
        state.copyWith(
          status: CartStatus.ready,
          items: const [],
          clearError: true,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(status: CartStatus.failure, error: error.toString()),
      );
    }
  }

  Set<String> _without(String recipeId) =>
      {...state.pendingRecipeIds}..remove(recipeId);
}
