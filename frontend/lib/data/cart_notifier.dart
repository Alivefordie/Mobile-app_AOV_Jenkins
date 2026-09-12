import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/data/mock_cart_items.dart';
import 'package:flutter_application_1/models/cart_item.dart';

class CartNotifier extends ValueNotifier<List<CartItem>> {
  CartNotifier() : super(mockCartItems);

  int get itemCount =>
      value.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      value.fold(0, (total, item) => total + item.lineTotal);

  void setQuantity(String id, int quantity) {
    final index = value.indexWhere((item) => item.id == id);
    if (index == -1) return;

    if (quantity < 1) {
      remove(id);
      return;
    }

    _replaceAt(index, value[index].copyWith(quantity: quantity));
  }

  void remove(String id) {
    value = value.where((item) => item.id != id).toList(growable: false);
  }

  void clear() => value = const [];

  void _replaceAt(int index, CartItem item) {
    final items = [...value];
    items[index] = item;
    value = items;
  }
}

final CartNotifier cartNotifier = CartNotifier();