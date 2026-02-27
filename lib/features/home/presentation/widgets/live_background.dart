import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LiveBackground extends StatelessWidget {
  final String lottieAsset;
  final double opacity;

  const LiveBackground({
    super.key,
    required this.lottieAsset,
    this.opacity = 1.0,
  });

  bool get isLottie => lottieAsset.toLowerCase().endsWith(".json");

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: isLottie
          ? Lottie.asset(
              lottieAsset,
              fit: BoxFit.cover,
              repeat: true,
            )
          : Image.asset(
              lottieAsset,
              fit: BoxFit.cover,
            ),
    );
  }
}
