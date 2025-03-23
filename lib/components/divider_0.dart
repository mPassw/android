import 'package:flutter/material.dart';

class DividerNoMargin extends StatelessWidget {
  const DividerNoMargin({super.key, this.color});

  final Color? color; // Add the color parameter

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 0,
      endIndent: 0,
      color: color, // Use the provided color
    );
  }
}
