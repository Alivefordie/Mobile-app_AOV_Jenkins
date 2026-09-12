import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String categoryId;
  final bool isSelected;
  final double itemWidth;
  final double iconSize;
  final double fontSize;
  final double verticalPadding;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.title,
    required this.categoryId,
    required this.isSelected,
    this.itemWidth = 80,
    this.iconSize = 30,
    this.fontSize = 12,
    this.verticalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<CategoryBloc>().add(CategorySelectEvent(categoryId)); //ส่ง id ไปหา api
        debugPrint('Selected category: $categoryId');
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemWidth,
        margin: const EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFFFF3E0), // ส้มอ่อนมาก
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE64A19).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected ? Colors.white : const Color(0xFFE64A19),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}