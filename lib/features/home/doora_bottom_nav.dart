import 'dart:ui'; // blur
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DooraBottomNav extends StatelessWidget {
  const DooraBottomNav({super.key, required int currentIndex, required Null Function(dynamic i) onChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(230, 255, 255, 255), // 90% white
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color.fromARGB(
                        180, 255, 255, 255), // light border
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(26, 0, 0, 0),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: "Home",
                      active: true,
                    ),
                    _NavItem(
                      icon: Icons.shopping_bag_outlined,
                      label: "Bookings",
                    ),
                    _NavItem(
                      icon: Icons.favorite_border_rounded,
                      label: "Saved",
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: "Profile",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = Colors.black54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color.fromARGB(40, 46, 111, 242) // brand blue with 16% tint
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: active ? 24 : 22,
            color: active ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 12,
              color: active ? activeColor : inactiveColor,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
