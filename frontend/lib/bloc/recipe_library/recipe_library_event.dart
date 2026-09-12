sealed class RecipeLibraryEvent {
  const RecipeLibraryEvent();
}

final class RecipeLibraryRequested extends RecipeLibraryEvent {
  const RecipeLibraryRequested();
}

final class RecipeLibraryRefreshRequested extends RecipeLibraryEvent {
  const RecipeLibraryRefreshRequested();
}
