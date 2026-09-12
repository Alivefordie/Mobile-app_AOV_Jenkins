import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/views/pages/cooking_steps_page.dart';
import 'package:flutter_application_1/widgets/food_detail/bottom_buy_bar.dart';
import 'package:flutter_application_1/widgets/food_detail/error_view.dart';
import 'package:flutter_application_1/widgets/food_detail/food_description.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_header.dart';
import 'package:flutter_application_1/widgets/food_detail/food_info_card.dart';
import 'package:flutter_application_1/widgets/food_detail/loading_view.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({super.key, required this.foodsId});

  final String foodsId;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Future<Food> _foodFuture;

  @override
  void initState() {
    super.initState();
    _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
  }

  void _reload() {
    setState(() {
      _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomBuyBar(
        onCartPressed: () {},
        onBuyPressed: () {},
      ),
      body: FutureBuilder<Food>(
        future: _foodFuture,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (state.hasError || !state.hasData) {
            return ErrorView(
              message: state.error?.toString() ?? 'ไม่พบข้อมูลเมนูนี้',
              onRetry: _reload,
            );
          }

          return _buildBody(state.data!);
        },
      ),
    );
  }

  Widget _buildBody(Food food) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            FoodDetailHeader(food: food),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 33),
                  //
                  FoodInfoCard(food: food),
                  const SizedBox(height: 30),
                  //
                  FoodDescription(description: food.description),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CookingStepsPage(food: food),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6650A5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.restaurant_menu_rounded),
                      label: const Text(
                        'เริ่มทำอาหาร',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
