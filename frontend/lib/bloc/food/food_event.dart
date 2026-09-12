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

class SearchFoodEvent extends FoodEvent {
  final String query;
  // หมวดที่เลือกอยู่ ค่าว่าง = ค้นหาทุกหมวด
  final String categoryId;
  SearchFoodEvent(this.query, {this.categoryId = ''});
}
