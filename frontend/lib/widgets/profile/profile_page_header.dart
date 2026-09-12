import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/cart_notifier.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    super.key,
    required this.onSettingsPressed,
    required this.onCartPressed,
  });

  final VoidCallback onSettingsPressed;
  final VoidCallback onCartPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: ProfileColors.ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Your recipes, orders and preferences',
                style: TextStyle(
                  color: ProfileColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _CartButton(onPressed: onCartPressed),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: onSettingsPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ProfileColors.ink,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cartNotifier,
      builder: (context, items, child) {
        final count = cartNotifier.itemCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ProfileColors.ink,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ProfileColors.background, width: 2),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: ProfileColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ProfileColors.ink,
          fixedSize: const Size(46, 46),
        ),
        icon: const Icon(Icons.shopping_bag_outlined),
        tooltip: 'Cart',
      ),
    );
  }
}