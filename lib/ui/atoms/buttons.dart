// lib/ui/atoms/buttons.dart
// ===============================
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool block;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.block = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Text(label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                )),
      ],
    );

    final btn = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: onPressed == null
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.card,
        ),
        child: child,
      ),
    );

    return block ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GhostButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
