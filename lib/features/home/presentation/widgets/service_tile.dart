// lib/features/home/widgets/service_tile.dart

import 'package:flutter/material.dart';
import '../../presentation/video_carousel.dart';

class ServiceTile extends StatefulWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  @override
  State<ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<ServiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const Color border = Color(0xFFE3E6F0);
    const Color bg = Colors.white;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);

        // 🔥 Force pause videos
        pauseAllVideoCarousels();

        // 👇 ab sheet open hogi
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.96 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICON BUBBLE – iOS style
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF3FF),
                      Color(0xFFE0ECFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E6FF2).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    widget.assetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // LABEL – clean iOS typography, NO UNDERLINE / HIGHLIGHT
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.2,
                  decoration: TextDecoration
                      .none, // 👈 force: koi underline / highlight nahi
                  decorationColor: Colors
                      .transparent, // 👈 agar kahin parent se aa raha ho to bhi off
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
