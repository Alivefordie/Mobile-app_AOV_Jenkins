import 'package:flutter/material.dart';

class CommunityCategoryHeader extends StatelessWidget {
  const CommunityCategoryHeader({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final bool isTablet = size.shortestSide >= 600;
    final bool isLandscape = size.width > size.height;

    // --------------------------------------------------
    // Responsive Header Height
    // --------------------------------------------------

    double expandedHeight;

    if (isTablet) {
      // iPad
      expandedHeight = isLandscape ? 300 : 400;
    } else {
      // Phone
      if (size.width >= 400) {
        expandedHeight = 270;
      } else {
        expandedHeight = 240;
      }
    }

    // --------------------------------------------------
    // Responsive Icon Size
    // --------------------------------------------------

    final double iconSize = isTablet ? 28 : 24;

    // --------------------------------------------------
    // Responsive Overlay
    // --------------------------------------------------

    final double overlayOpacity = isTablet ? 0.18 : 0.22;

return SliverAppBar(
  pinned: true,
  floating: false,
  snap: false,

  expandedHeight: expandedHeight,

  collapsedHeight: kToolbarHeight,
  toolbarHeight: kToolbarHeight,

  backgroundColor: Colors.grey.shade100,

  iconTheme: IconThemeData(
    color: Colors.white,
    size: iconSize,
  ),

  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),

            Container(
              color: Colors.black.withValues(
                alpha: overlayOpacity,
              ),
            ),
          ],
        ),
      );
    },
  ),
);
  }
}