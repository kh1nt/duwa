import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DuwaLogoSize { small, medium, large, hero }

/// The official brand identity for DUWA — "The Gamepad D".
/// Features a single, clean squircle tile housing the Gamepad D symbol
/// (directional D-pad on the left meeting a curved controller grip with twin action buttons).
/// Features interactive haptics, spring animations, and luminous ambient pulse.
class DuwaLogo extends StatefulWidget {
  final DuwaLogoSize size;
  final bool showWordmark;
  final Color? textColor;
  final bool withGlow;
  final double? customSize;
  final bool isEmblemOnly;
  final VoidCallback? onTap;

  const DuwaLogo({
    super.key,
    this.size = DuwaLogoSize.medium,
    this.showWordmark = true,
    this.textColor,
    this.withGlow = false,
    this.customSize,
    this.isEmblemOnly = false,
    this.onTap,
  });

  @override
  State<DuwaLogo> createState() => _DuwaLogoState();
}

class _DuwaLogoState extends State<DuwaLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.90)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_tapController);

    _glowAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _tapController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final (iconSize, fontSize) = switch (widget.size) {
      DuwaLogoSize.small => (32.0, 16.0),
      DuwaLogoSize.medium => (42.0, 22.0),
      DuwaLogoSize.large => (64.0, 32.0),
      DuwaLogoSize.hero => (100.0, 40.0),
    };

    final effectiveIconSize = widget.customSize ?? iconSize;
    final effectiveTextColor = widget.textColor ?? Theme.of(context).colorScheme.onSurface;

    Widget emblemWidget = GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final glowMultiplier = _glowAnimation.value;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: effectiveIconSize,
              height: effectiveIconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient Solar Flame glow aura behind the emblem
                  if (widget.withGlow || _tapController.isAnimating)
                    Container(
                      width: effectiveIconSize * 0.85,
                      height: effectiveIconSize * 0.85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(effectiveIconSize * 0.22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E1E).withAlpha(
                              ((widget.withGlow ? 110 : 50) * glowMultiplier)
                                  .clamp(0, 255)
                                  .toInt(),
                            ),
                            blurRadius: effectiveIconSize * 0.45 * glowMultiplier,
                            spreadRadius: effectiveIconSize * 0.05 * glowMultiplier,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFA114).withAlpha(
                              ((widget.withGlow ? 60 : 25) * glowMultiplier)
                                  .clamp(0, 255)
                                  .toInt(),
                            ),
                            blurRadius: effectiveIconSize * 0.70 * glowMultiplier,
                            spreadRadius: effectiveIconSize * 0.08 * glowMultiplier,
                          ),
                        ],
                      ),
                    ),

                  // DUWA Gamepad Logo (Clean single squircle tile with no outer background border)
                  if (widget.isEmblemOnly)
                    Image.asset(
                      'assets/images/duwa_gamepad_logo.png',
                      width: effectiveIconSize,
                      height: effectiveIconSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: effectiveIconSize,
                        height: effectiveIconSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(effectiveIconSize * 0.22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E1E), Color(0xFFFFA114)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          size: effectiveIconSize * 0.55,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(effectiveIconSize * 0.22),
                      child: Image.asset(
                        'assets/images/duwa_icon_tile_clean.png',
                        width: effectiveIconSize,
                        height: effectiveIconSize,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: effectiveIconSize,
                          height: effectiveIconSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(effectiveIconSize * 0.22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E1E), Color(0xFFFFA114)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.sports_esports_rounded,
                            size: effectiveIconSize * 0.55,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!widget.showWordmark) {
      return emblemWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblemWidget,
        SizedBox(width: effectiveIconSize * 0.24),
        Text(
          'DUWA',
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

