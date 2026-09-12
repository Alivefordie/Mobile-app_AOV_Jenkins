import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// หน้าแสดง error พร้อมปุ่มย้อนกลับ / ลองอีกครั้ง
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: FoodDetailColors.accentOrange,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text("ย้อนกลับ"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FoodDetailColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("ลองอีกครั้ง"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}