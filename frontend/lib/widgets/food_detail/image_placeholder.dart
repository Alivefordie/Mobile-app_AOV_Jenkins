import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// ไอคอนแทนรูป เวลาไม่มีรูป หรือโหลดรูปไม่สำเร็จ
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 64,
          color: FoodDetailColors.accentOrange,
        ),
      ),
    );
  }
}