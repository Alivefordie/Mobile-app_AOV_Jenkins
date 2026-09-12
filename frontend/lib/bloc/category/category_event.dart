abstract class CategoryEvent {
  CategoryEvent();
}

class FetchCategoriesEvent extends CategoryEvent {
  FetchCategoriesEvent();
}

class CategorySelectEvent extends CategoryEvent {
  final String id;
  CategorySelectEvent(this.id);
}
