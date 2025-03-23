import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MpassLoader extends StatelessWidget {
  const MpassLoader({super.key, this.width = 200, this.height = 200});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/mPass_lottie_dark.json', // Make sure path is correct or configurable
      width: width,
      height: height,
      repeat: true,
      reverse: false,
      animate: true,
    );
  }
}
