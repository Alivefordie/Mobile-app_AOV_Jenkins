import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/views/pages/recipe_collection_page.dart';

class FavoriteRecipesPage extends StatelessWidget {
  const FavoriteRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecipeCollectionPage(
      collectionType: RecipeCollectionType.favorites,
    );
  }
}
