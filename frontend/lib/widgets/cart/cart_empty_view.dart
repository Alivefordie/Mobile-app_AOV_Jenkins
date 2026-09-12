import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key, required this.onBrowsePressed});

  final VoidCallback onBrowsePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: ProfileColors.muted,
              size: 56,
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                color: ProfileColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recipes you add will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ProfileColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onBrowsePressed,
              style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Browse recipes'),
            ),
          ],
        ),
      ),
    );
  }
}