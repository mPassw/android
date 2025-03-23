import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.element});

  final Widget element;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
        baseColor: Colors.grey[isDarkMode ? 800 : 300]!,
        highlightColor: Colors.grey[isDarkMode ? 600 : 100]!,
        child: element);
  }
}
