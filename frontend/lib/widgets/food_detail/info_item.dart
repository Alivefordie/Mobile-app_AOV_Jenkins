import 'package:flutter/material.dart';

/// หนึ่งช่องใน [FoodInfoCard] เช่น "15 น." / "prep"
class InfoItem extends StatelessWidget {
  const InfoItem({super.key, required this.value, required this.title});

  final String value;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}