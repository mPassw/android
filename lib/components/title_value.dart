import 'package:flutter/material.dart';

class InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const InfoItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, color: Colors.grey[isDarkMode ? 500 : 600]),
        ),
      ],
    );
  }
}
