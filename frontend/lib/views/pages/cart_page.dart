import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/cart_notifier.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/widgets/cart/cart_empty_view.dart';
import 'package:flutter_application_1/widgets/cart/cart_item_tile.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature is coming soon'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ProfileColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

//
  Future<void> _confirmClear(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes every recipe from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cartNotifier.clear();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

//
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cartNotifier,
      builder: (context, items, _) {
        return Scaffold(
          backgroundColor: ProfileColors.background,
          appBar: AppBar(
            backgroundColor: ProfileColors.background,
            foregroundColor: ProfileColors.ink,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Cart',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Clear cart',
                ),
            ],
          ),
          body: items.isEmpty
              ? CartEmptyView(onBrowsePressed: () => Navigator.pop(context))
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return CartItemTile(
                      item: item,
                      onQuantityChanged: (quantity) =>
                          cartNotifier.setQuantity(item.id, quantity),
                      onRemove: () => cartNotifier.remove(item.id),
                    );
                  },
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : CartSummaryBar(
                  itemCount: cartNotifier.itemCount,
                  subtotal: cartNotifier.subtotal,
                  onCheckoutPressed: () => _showComingSoon(context, 'Checkout'),
                ),
        );
      },
    );
  }
}