import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: FoodDetailColors.primaryRed,
        strokeWidth: 3,
      ),
    );
  }
}