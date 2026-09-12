import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';

enum TacticalBadgeVariant {
  live,      // Pulsing red/coral beacon
  ready,     // Ion mint glow
  flame,     // Solar flame / amber urgency
  neutral,   // Subtle tactical slate
  accent,    // Hyper indigo / cyber teal
}

/// Tactical micro-badge with high-contrast typography, dot beacons, and optional glow.
class TacticalBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TacticalBadgeVariant variant;
  final bool hasPulseDot;
  final double fontSize;
  final EdgeInsets padding;

  const TacticalBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = TacticalBadgeVariant.neutral,
    this.hasPulseDot = false,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, text, dotColor) = switch (variant) {
      TacticalBadgeVariant.live => (
        DuwaColors.errorRed.withAlpha(30),
        DuwaColors.errorRed.withAlpha(140),
        const Color(0xFFFF6B6B),
        DuwaColors.errorRed,
      ),
      TacticalBadgeVariant.ready => (
        DuwaColors.ionMint.withAlpha(26),
        DuwaColors.ionMint.withAlpha(130),
        DuwaColors.ionMint,
        DuwaColors.ionMint,
      ),
      TacticalBadgeVariant.flame => (
        DuwaColors.solarFlame.withAlpha(30),
        DuwaColors.solarFlame.withAlpha(140),
        DuwaColors.emberGold,
        DuwaColors.solarFlame,
      ),
      TacticalBadgeVariant.accent => (
        DuwaColors.hyperIndigo.withAlpha(30),
        DuwaColors.hyperIndigo.withAlpha(140),
        const Color(0xFFA5B4FC),
        DuwaColors.hyperIndigo,
      ),
      TacticalBadgeVariant.neutral => (
        Colors.white.withAlpha(16),
        Colors.white.withAlpha(40),
        Colors.white.withAlpha(210),
        Colors.white,
      ),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasPulseDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: text,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
