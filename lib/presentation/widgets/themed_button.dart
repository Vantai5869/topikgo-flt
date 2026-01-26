import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ThemedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const ThemedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? AppColors.glassDark : AppColors.glassLight;
    final defaultBorderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBgColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? defaultBorderColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
