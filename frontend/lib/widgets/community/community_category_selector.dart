import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/community/category_header_delegate.dart';

class CommunityCategorySelector extends StatelessWidget {
  const CommunityCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(Category category) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: CategoryHeaderDelegate(
        child: Container(
          height: 60,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              final isSelected =
                  selectedCategoryId == category.id;

              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    return;
                  }

                  onCategorySelected(category);
                },
                child: Card(
                  elevation: isSelected ? 8 : 3,
                  color: isSelected
                      ? Colors.blue.shade100
                      : Colors.white,
                  margin: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}