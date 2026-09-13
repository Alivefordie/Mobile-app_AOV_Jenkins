import 'package:flutter_application_1/models/cart_item.dart';

enum CartStatus { initial, loading, ready, failure }

/// ผลของการกดปุ่ม + ครั้งล่าสุด ใช้สั่งให้หน้าจอเด้ง SnackBar
enum CartFeedback { none, added, alreadyInCart, failed }

class CartState {
  const CartState({
    this.status = CartStatus.initial,
    this.cartId,
    this.items = const [],
    this.pendingRecipeIds = const {},
    this.feedback = CartFeedback.none,
    this.feedbackTitle,
    this.error,
  });

  final CartStatus status;

  /// ตะกร้าถูกสร้างตอนกดเพิ่มครั้งแรก ก่อนหน้านั้นยังเป็น null
  final String? cartId;

  final List<CartItem> items;

  /// สูตรที่กำลังยิง API อยู่ ใช้กันกดรัว ๆ ซ้อนกัน
  final Set<String> pendingRecipeIds;

  final CartFeedback feedback;
  final String? feedbackTitle;
  final String? error;

  int get itemCount => items.length;

  // สูตรเป็นสินค้า digital ชิ้นละหนึ่ง ยอดรวมจึงเป็นผลบวกราคาตรง ๆ
  double get subtotal =>
      items.fold(0, (total, item) => total + item.price);

  bool contains(String recipeId) =>
      items.any((item) => item.recipeId == recipeId);

  bool isPending(String recipeId) => pendingRecipeIds.contains(recipeId);

  CartState copyWith({
    CartStatus? status,
    String? cartId,
    List<CartItem>? items,
    Set<String>? pendingRecipeIds,
    CartFeedback? feedback,
    String? feedbackTitle,
    String? error,
    bool clearError = false,
  }) {
    return CartState(
      status: status ?? this.status,
      cartId: cartId ?? this.cartId,
      items: items ?? this.items,
      pendingRecipeIds: pendingRecipeIds ?? this.pendingRecipeIds,
      feedback: feedback ?? CartFeedback.none,
      feedbackTitle: feedback == null ? null : feedbackTitle,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
