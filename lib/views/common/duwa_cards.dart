import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../models/game_night_model.dart';

class DuwaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const DuwaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.border,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorder = border ??
        Border.all(
          color: theme.dividerColor,
          width: 1,
        );

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? theme.cardColor) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

class DuwaBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  const DuwaBadge({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  factory DuwaBadge.fromStatus(GameNightStatus status) {
    switch (status) {
      case GameNightStatus.draft:
        return const DuwaBadge(
          label: 'Draft',
          icon: Icons.edit_note_rounded,
          backgroundColor: Color(0xFF1E293B),
          textColor: DuwaColors.textMuted,
        );
      case GameNightStatus.voting:
        return const DuwaBadge(
          label: 'Voting',
          icon: Icons.how_to_vote_outlined,
          backgroundColor: Color(0xFF78350F),
          textColor: DuwaColors.warningOrange,
        );
      case GameNightStatus.planning:
        return const DuwaBadge(
          label: 'Planning',
          icon: Icons.pending_outlined,
          backgroundColor: Color(0xFF1E3A8A),
          textColor: DuwaColors.blueIris,
        );
      case GameNightStatus.ready:
        return const DuwaBadge(
          label: 'Ready',
          icon: Icons.check_circle_outline,
          backgroundColor: Color(0xFF064E3B),
          textColor: DuwaColors.successGreen,
        );
      case GameNightStatus.completed:
        return const DuwaBadge(
          label: 'Completed',
          icon: Icons.history,
          backgroundColor: Color(0xFF334155),
          textColor: DuwaColors.textMuted,
        );
      case GameNightStatus.cancelled:
        return const DuwaBadge(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          backgroundColor: Color(0xFF450A0A),
          textColor: DuwaColors.errorRed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(200),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withAlpha(76), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
