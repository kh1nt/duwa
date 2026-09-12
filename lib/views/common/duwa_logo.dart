import 'package:flutter/material.dart';

enum DuwaLogoSize { small, medium, large }

/// Sleek, modern geometric brand identity for DUWA.
/// Designed to feel market-competitive, social, energetic, and clean.
class DuwaLogo extends StatelessWidget {
  final DuwaLogoSize size;
  final bool showWordmark;
  final bool showBadge;
  final Color? textColor;

  const DuwaLogo({
    super.key,
    this.size = DuwaLogoSize.medium,
    this.showWordmark = true,
    this.showBadge = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final (iconSize, fontSize, badgePadding) = switch (size) {
      DuwaLogoSize.small => (32.0, 16.0, 3.0),
      DuwaLogoSize.medium => (42.0, 22.0, 4.0),
      DuwaLogoSize.large => (64.0, 32.0, 6.0),
    };

    final effectiveTextColor = textColor ?? Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Geometric Emblem
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconSize * 0.32),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withAlpha(90),
                blurRadius: iconSize * 0.35,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Controller / D-pad subtle overlay
              Icon(
                Icons.sports_esports_rounded,
                size: iconSize * 0.58,
                color: Colors.white,
              ),
              // Corner jewel accent
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: iconSize * 0.18,
                  height: iconSize * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399), // Emerald pulse
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showWordmark) ...[
          SizedBox(width: iconSize * 0.26),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DUWA',
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: badgePadding + 3, vertical: badgePadding * 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4F46E5).withAlpha(80), width: 0.8),
                      ),
                      child: const Text(
                        'SQUAD',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
