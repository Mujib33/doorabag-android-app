import 'package:flutter/material.dart';
import 'package:doora_app/theme/app_theme.dart';

class FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
        ),
      ),
    );
  }
}
