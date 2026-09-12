abstract class FoodEvent {
  FoodEvent();
}

class FetchFoodEvent extends FoodEvent {
  FetchFoodEvent();
}

class FetchFoodByCategoryEvent extends FoodEvent {
  final String categoryId;
  FetchFoodByCategoryEvent(this.categoryId);
}

class FetchCommunityFoodsByCategoryEvent extends FoodEvent {
  final String categoryId;
  FetchCommunityFoodsByCategoryEvent(this.categoryId);
}
