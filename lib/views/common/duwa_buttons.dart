import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import 'bouncy_tap.dart';

enum DuwaButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class DuwaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DuwaButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final double height;
  final DuwaThemeData? themeOverride;

  const DuwaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DuwaButtonVariant.primary,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 50,
    this.themeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final duwaTheme = themeOverride ??
        (Theme.of(context).brightness == Brightness.dark
            ? DuwaThemeData.obsidianVoid()
            : DuwaThemeData.cleanLight());

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == DuwaButtonVariant.primary
                    ? duwaTheme.surfaceLowest
                    : duwaTheme.primaryAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    Decoration decoration;
    Color textColor = Colors.white;

    switch (variant) {
      case DuwaButtonVariant.primary:
        decoration = BoxDecoration(
          color: duwaTheme.primaryAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: duwaTheme.primaryAccent.withAlpha(65),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = duwaTheme.surfaceLowest;
        break;
      case DuwaButtonVariant.secondary:
        decoration = BoxDecoration(
          color: duwaTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duwaTheme.cardBorder, width: 1),
        );
        textColor = duwaTheme.textPrimary;
        break;
      case DuwaButtonVariant.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duwaTheme.secondaryAccent, width: 1.5),
        );
        textColor = duwaTheme.highlight;
        break;
      case DuwaButtonVariant.ghost:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        );
        textColor = duwaTheme.textSecondary;
        break;
    }

    return BouncyTap(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: decoration,
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          child: IconTheme(
            data: IconThemeData(color: textColor),
            child: content,
          ),
        ),
      ),
    );
  }
}

class DuwaFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;

  const DuwaFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DuwaColors.danubeBlue.withAlpha(51)
              : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DuwaColors.blueIris : Colors.white.withAlpha(25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? DuwaColors.grayFlash : DuwaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
