import 'package:flutter/material.dart';

class CategoryHeaderDelegate 
    extends SliverPersistentHeaderDelegate {

  final Widget child;

  CategoryHeaderDelegate({
    required this.child,
  });


  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }


  @override
  double get maxExtent => 60;


  @override
  double get minExtent => 60;


  @override
  bool shouldRebuild(
    covariant CategoryHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.child != child;
  }
}