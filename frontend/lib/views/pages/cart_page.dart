import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/widgets/cart/cart_empty_view.dart';
import 'package:flutter_application_1/widgets/cart/cart_item_tile.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final cartBloc = context.read<CartBloc>();

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
              cartBloc.add(const CartCleared());
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
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final items = state.items;

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
          body: switch (state.status) {
            // โหลดรอบแรกยังไม่รู้ว่ามีอะไรในตะกร้า อย่าเพิ่งบอกว่าว่าง
            CartStatus.initial ||
            CartStatus.loading when items.isEmpty => const Center(
              child: CircularProgressIndicator(),
            ),
            CartStatus.failure when items.isEmpty => _CartErrorView(
              message: state.error ?? 'Could not load your cart.',
              onRetry: () => context.read<CartBloc>().add(const CartRequested()),
            ),
            _ when items.isEmpty => CartEmptyView(
              onBrowsePressed: () => Navigator.pop(context),
            ),
            _ => ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return CartItemTile(
                  item: item,
                  onRemove: () =>
                      context.read<CartBloc>().add(CartItemRemoved(item.id)),
                );
              },
            ),
          },
          bottomNavigationBar: items.isEmpty
              ? null
              : CartSummaryBar(
                  itemCount: state.itemCount,
                  subtotal: state.subtotal,
                  onCheckoutPressed: () => _showComingSoon(context, 'Checkout'),
                ),
        );
      },
    );
  }
}

// โหลดตะกร้าไม่ได้ตั้งแต่แรก ให้กดลองใหม่ได้
class _CartErrorView extends StatelessWidget {
  const _CartErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ProfileColors.muted,
              size: 56,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ProfileColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
