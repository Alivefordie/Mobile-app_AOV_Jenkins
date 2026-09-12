import 'package:flutter/material.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // < 600 มือถือ, >= 600 iPad
        final isMedium = width >= 600;

        final height = isMedium ? 260.0 : 206.0;
        final padding = isMedium ? 28.0 : 20.0;
        final titleSize = isMedium ? 30.0 : 24.0;
        final subtitleSize = isMedium ? 16.0 : 14.0;

        return Card(
          elevation: 6,
          shadowColor: const Color(0xFFE64A19).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD32F2F), // แดงสด
                  Color(0xFFF57C00), // ส้มอุ่น
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Free Delivery\nFor Spaghetti",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Up to 3 times per day",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEB3B), // เหลืองสด
                            foregroundColor: const Color(0xFFD32F2F),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMedium ? 28 : 20,
                              vertical: isMedium ? 16 : 12,
                            ),
                          ),
                          child: Text(
                            "Order Now",
                            style: TextStyle(
                              fontSize: isMedium ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Image.network(
                    "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9",
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}