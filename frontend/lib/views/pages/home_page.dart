import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
import 'package:flutter_application_1/widgets/home/home_banner.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_application_1/widgets/home/section_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final selectedId = context
        .read<CategoryBloc>()
        .state
        .selectedId; // อ่าน id ของ CategoryBloc
    context.read<FoodBloc>().add(
      FetchFoodByCategoryEvent(selectedId),
    ); // ดึงข้อมูลตาม food by CategoryBloc
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SearchBarWidget(),

              const SizedBox(height: 20),

              const HomeBanner(),

              const SizedBox(height: 25),

              const CategoryList(),

              const SizedBox(height: 25),

              const SectionTitle(),

              const SizedBox(height: 20),

              BlocBuilder<FoodBloc, FoodState>(
                builder: (context, state) {
                  if (state is FoodInitial) {
                    return const Center(child: Text("Initial Loading..."));
                  }
                  if (state is FoodLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is FoodLoaded) {
                    if (state.foods.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'ยังไม่มีเมนูในหมวดนี้',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        // < 600 มือถือ = 2 คอลัมน์, >= 600 iPad = 3 คอลัมน์
                        final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.foods.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: .68,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                          itemBuilder: (_, index) {
                            final food = state.foods[index];
                            return FoodCard(
                              food: food,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FoodDetailPage(foodsId: food.idfoods),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }
                  // handle error state
                  if (state is FoodError) {
                    return Center(child: Text(state.message));
                  }
                  // return empty widget
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
