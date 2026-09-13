enum FavoriteStatus { initial, loading, ready, failure }

class FavoriteState {
  const FavoriteState({
    this.status = FavoriteStatus.initial,
    this.recipeIds = const {},
    this.pendingRecipeIds = const {},
    this.error,
  });

  final FavoriteStatus status;

  /// id ของสูตรที่ถูกกดหัวใจไว้
  final Set<String> recipeIds;

  /// สูตรที่กำลังยิง API อยู่ ใช้กันกดรัว ๆ ซ้อนกัน
  final Set<String> pendingRecipeIds;

  final String? error;

  bool isFavorite(String recipeId) => recipeIds.contains(recipeId);

  bool isPending(String recipeId) => pendingRecipeIds.contains(recipeId);

  FavoriteState copyWith({
    FavoriteStatus? status,
    Set<String>? recipeIds,
    Set<String>? pendingRecipeIds,
    String? error,
    bool clearError = false,
  }) {
    return FavoriteState(
      status: status ?? this.status,
      recipeIds: recipeIds ?? this.recipeIds,
      pendingRecipeIds: pendingRecipeIds ?? this.pendingRecipeIds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
