enum RecipeCollectionType { myRecipes, purchased, favorites, drafts }

extension RecipeCollectionTypeText on RecipeCollectionType {
  String get title => switch (this) {
    RecipeCollectionType.myRecipes => 'My recipes',
    RecipeCollectionType.purchased => 'Purchased',
    RecipeCollectionType.favorites => 'Favorites',
    RecipeCollectionType.drafts => 'Drafts',
  };

  String get emptyMessage => switch (this) {
    RecipeCollectionType.myRecipes => 'You have not published a recipe yet.',
    RecipeCollectionType.purchased => 'You have not purchased a recipe yet.',
    RecipeCollectionType.favorites => 'Your saved recipes will appear here.',
    RecipeCollectionType.drafts => 'You have no unfinished recipes.',
  };
}
