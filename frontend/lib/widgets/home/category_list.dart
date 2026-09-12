import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';

import 'category_item.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  static const Map<String, IconData> _icons = {
    'noodles': Icons.ramen_dining,
    'made-to-order': Icons.restaurant,
    'fire-chiken': Icons.fastfood,
    'good-food': Icons.eco,
    'spicy-thai-salad': Icons.local_fire_department,
    'bubble-tea': Icons.emoji_food_beverage,
    'dipping-sauce': Icons.water_drop,
    'grill': Icons.outdoor_grill,
    'thai-food': Icons.rice_bowl,
  };

  static IconData _iconFor(String slug) =>
      _icons[slug.trim().toLowerCase()] ?? Icons.restaurant_menu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // >= 900 แท็บเล็ตใหญ่/แนวนอน, >= 600 แท็บเล็ต, < 600 มือถือ
        final double listHeight;
        final double itemWidth;
        final double iconSize;
        final double fontSize;
        final double verticalPadding;

        if (width >= 900) {
          listHeight = 130.0;
          itemWidth = 120.0;
          iconSize = 44.0;
          fontSize = 16.0;
          verticalPadding = 18.0;
        } else if (width >= 600) {
          listHeight = 110.0;
          itemWidth = 100.0;
          iconSize = 38.0;
          fontSize = 14.0;
          verticalPadding = 16.0;
        } else {
          listHeight = 90.0;
          itemWidth = 80.0;
          iconSize = 30.0;
          fontSize = 12.0;
          verticalPadding = 12.0;
        }

        return BlocConsumer<CategoryBloc, CategoryState>(
          listenWhen: (previous, current) =>
              previous.selectedId != current.selectedId,
          listener: (context, state) {
            context.read<FoodBloc>().add(
              FetchFoodByCategoryEvent(state.selectedId),
            );
          },
          builder: (context, state) {
            if (state is CategoryLoading) {
              return SizedBox(
                height: listHeight,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CategoryError) {
              return SizedBox(
                height: listHeight,
                child: Center(child: Text(state.message)),
              );
            }

            if (state is! CategoryLoaded) {
              return SizedBox(height: listHeight);
            }

            return SizedBox(
              height: listHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                itemBuilder: (_, index) {
                  final category = state.categories[index];
                  return CategoryItem(
                    icon: _iconFor(category.slug),
                    title: category.name,
                    categoryId: category.id,
                    isSelected: state.selectedId == category.id,
                    itemWidth: itemWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPadding: verticalPadding,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}