import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/food_image.dart';

// พื้นหลังโค้ง ปุ่มย้อนกลับ  รูปอาหาร
class FoodDetailHeader extends StatelessWidget {
  const FoodDetailHeader({super.key, required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 320,
          decoration: const BoxDecoration(
            color: FoodDetailColors.softOrange,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: FoodDetailColors.primaryRed,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        SizedBox(
          height: 320,
          child: Center(
            child: FoodImage(
              heroTag: food.idfoods,
              imageUrl: food.filePathImage,
            ),
          ),
        ),
      ],
    );
  }
}