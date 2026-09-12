import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/main_tree.dart';
import 'package:flutter_application_1/views/pages/cart_page.dart';
import 'package:flutter_application_1/views/pages/community_page.dart';
import 'package:flutter_application_1/views/pages/community_selectcategory_page.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/views/pages/draft_recipes_page.dart';
import 'package:flutter_application_1/views/pages/favorite_recipes_page.dart';
import 'package:flutter_application_1/views/pages/my_recipes_page.dart';
import 'package:flutter_application_1/views/pages/purchased_recipes_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesGenerator {
  static Route<dynamic> generateRoute(RouteSettings setting) {
    switch (setting.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              //BlocProvider(create: (context) => CounterBloc()),
              BlocProvider(create: (context) => PageBloc()),
              BlocProvider(
                create: (context) =>
                    CategoryBloc(CategoryRepository())
                      ..add(FetchCategoriesEvent()),
              ),
              BlocProvider(create: (context) => FoodBloc(FoodRepository())),
              BlocProvider(
                create: (context) => ProfileBloc(
                  HttpProfileRepository(baseUrl: ApiConfig.apiBaseUrl),
                  userId: ApiConfig.profileUserId,
                )..add(const ProfileRequested()),
              ),
            ],
            child: const MainTreeWidget(title: 'Flutter App'),
          ),
        );

      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartPage());

      case AppRoutes.community:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => CategoryBloc(
              CategoryRepository(),
            )..add(
                FetchCategoriesEvent(),
              ),
            child: const CommunityPage(),
          ),
        );

      case AppRoutes.communitySelectCategory:
        final args = setting.arguments as Map<String, dynamic>;

        final String categoryUUID = args['categoryUUID'];
        final String categoryImageUrl = args['categoryImageUrl'];

        final CategoryBloc categoryBloc = args['categoryBloc'];

        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: categoryBloc,
              ),
              BlocProvider(
                create: (_) => FoodBloc(
                  FoodRepository(),
                ),
              ),
            ],
            child: CommunitySelectCategoryPage(
              categoryUUID: categoryUUID,
              categoryImageUrl: categoryImageUrl,
            ),
          ),
        );

      case AppRoutes.foodDetail:
        final String foodId = setting.arguments as String;

        return MaterialPageRoute(
          builder: (_) => FoodDetailPage(
            foodsId: foodId,
          ),
        );

      case AppRoutes.myRecipes:
        return _recipeCollectionRoute(
          RecipeCollectionType.myRecipes,
          const MyRecipesPage(),
        );
      case AppRoutes.purchasedRecipes:
        return _recipeCollectionRoute(
          RecipeCollectionType.purchased,
          const PurchasedRecipesPage(),
        );
      case AppRoutes.favoriteRecipes:
        return _recipeCollectionRoute(
          RecipeCollectionType.favorites,
          const FavoriteRecipesPage(),
        );
      case AppRoutes.draftRecipes:
        return _recipeCollectionRoute(
          RecipeCollectionType.drafts,
          const DraftRecipesPage(),
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _recipeCollectionRoute(
    RecipeCollectionType collectionType,
    Widget page,
  ) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => RecipeLibraryBloc(
          HttpRecipeLibraryRepository(baseUrl: ApiConfig.apiBaseUrl),
          userId: ApiConfig.profileUserId,
          collectionType: collectionType,
        )..add(const RecipeLibraryRequested()),
        child: page,
      ),
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return const Scaffold(body: Center(child: Text('No route defined')));
      },
    );
  }
}
