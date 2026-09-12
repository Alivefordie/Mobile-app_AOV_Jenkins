import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/info_item.dart';

/// กล่องสรุปข้อมูล prep / cook / servings / level
class FoodInfoCard extends StatelessWidget {
  const FoodInfoCard({super.key, required this.food});

  final Food food;

  static String _minutes(int? value) => value == null ? "-" : "$value น.";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: FoodDetailColors.softOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InfoItem(value: _minutes(food.preparationMinutes), title: "prep"),
          InfoItem(value: _minutes(food.cookingMinutes), title: "cook"),
          InfoItem(
            value: food.servingCount?.toString() ?? "-",
            title: "servings",
          ),
          InfoItem(value: food.difficulty ?? "-", title: "level"),
        ],
      ),
    );
  }
}