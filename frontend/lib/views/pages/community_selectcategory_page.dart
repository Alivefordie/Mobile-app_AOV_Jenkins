import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/widgets/community/community_category_header.dart';
import 'package:flutter_application_1/widgets/community/community_category_selector.dart';
import 'package:flutter_application_1/widgets/community/community_food_grid.dart';

class CommunitySelectCategoryPage extends StatefulWidget {
  const CommunitySelectCategoryPage({
    super.key,
    required this.categoryUUID,
    required this.categoryImageUrl,
  });

  final String categoryUUID;
  final String categoryImageUrl;

  @override
  State<CommunitySelectCategoryPage> createState() =>
      _CommunitySelectCategoryPageState();
}

class _CommunitySelectCategoryPageState
    extends State<CommunitySelectCategoryPage> {

  String? selectedCategoryId;
  late String categoryImageUrl;

  @override
  void initState() {
    super.initState();

    categoryImageUrl = widget.categoryImageUrl;
    selectedCategoryId = widget.categoryUUID;

    final foodBloc = context.read<FoodBloc>();

    if (foodBloc.state is! FoodLoaded &&
        foodBloc.state is! FoodLoading) {
      foodBloc.add(
        FetchCommunityFoodsByCategoryEvent(widget.categoryUUID),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: BlocBuilder<FoodBloc, FoodState>(
          builder: (context, state) {
            if (state is FoodLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is FoodLoaded) {
              return CustomScrollView(
                slivers: [
                  CommunityCategoryHeader(
                    imageUrl: categoryImageUrl,
                  ),

                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, categoryState) {
                      if (categoryState is! CategoryLoaded) {
                        return const SliverToBoxAdapter(
                          child: SizedBox(),
                        );
                      }

                      return CommunityCategorySelector(
                        categories: categoryState.categories,
                        selectedCategoryId: selectedCategoryId,
                        onCategorySelected: (category) {
                          setState(() {
                            selectedCategoryId = category.id;
                            categoryImageUrl =
                                category.imageUrl ?? '';
                          });

                          context.read<FoodBloc>().add(
                                FetchCommunityFoodsByCategoryEvent(
                                  category.id,
                                ),
                              );
                        },
                      );
                    },
                  ),

                  CommunityFoodGrid(
                    foods: state.foods,
                  ),
                ],
              );
            }

            if (state is FoodError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                ),
              );
            }

            return const Center(
              child: Text('No data available.'),
            );
          },
        ),
      ),
    );
  }
}