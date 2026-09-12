import 'package:flutter_application_1/models/recipe_summary.dart';

sealed class RecipeLibraryState {
  const RecipeLibraryState();
}

final class RecipeLibraryInitial extends RecipeLibraryState {
  const RecipeLibraryInitial();
}

final class RecipeLibraryLoading extends RecipeLibraryState {
  const RecipeLibraryLoading();
}

final class RecipeLibraryLoaded extends RecipeLibraryState {
  const RecipeLibraryLoaded(this.recipes);

  final List<RecipeSummary> recipes;
}

final class RecipeLibraryFailure extends RecipeLibraryState {
  const RecipeLibraryFailure(this.message);

  final String message;
}
