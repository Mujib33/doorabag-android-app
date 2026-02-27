import 'package:flutter/material.dart';

class BigHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxExtentHeight;
  final double minExtentHeight;
  final Widget Function(BuildContext context, double t) headerBuilder;

  BigHeaderDelegate({
    required this.maxExtentHeight,
    required this.minExtentHeight,
    required this.headerBuilder,
  });

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return headerBuilder(context, t);
  }

  @override
  bool shouldRebuild(covariant BigHeaderDelegate old) =>
      old.maxExtentHeight != maxExtentHeight ||
      old.minExtentHeight != minExtentHeight ||
      old.headerBuilder != headerBuilder;
}
