import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import 'duwa_logo.dart';

/// Ultra-modern, market-competitive animated splash & loading screen for DUWA.
/// Features atmospheric ambient lighting, iridescent emblem pulse, and sleek sync status.
class DuwaLoadingScreen extends StatefulWidget {
  final DuwaThemeData duwaTheme;
  final String statusText;
  final VoidCallback? onFinished;
  final Duration duration;

  const DuwaLoadingScreen({
    super.key,
    required this.duwaTheme,
    this.statusText = 'Syncing squad sessions...',
    this.onFinished,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<DuwaLoadingScreen> createState() => _DuwaLoadingScreenState();
}

class _DuwaLoadingScreenState extends State<DuwaLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    if (widget.onFinished != null) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          widget.onFinished!();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    final isDark = t.isDark;

    final bgGradientStart = isDark ? const Color(0xFF0D1429) : const Color(0xFFF1F5F9);
    final bgGradientEnd = isDark ? const Color(0xFF050814) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: Stack(
        children: [
          // 1. Ambient Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.15),
                  radius: 1.1,
                  colors: [
                    bgGradientStart,
                    bgGradientEnd,
                  ],
                ),
              ),
            ),
          ),

          // 2. Neon Aura Glow Behind Logo
          Align(
            alignment: const Alignment(0.0, -0.15),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.85 + (_pulseController.value * 0.25);
                final opacity = 0.35 + (_pulseController.value * 0.35);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          DuwaColors.solarFlame.withValues(alpha: opacity * 0.45),
                          DuwaColors.emberGold.withValues(alpha: opacity * 0.25),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Central Brand Composition
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Central Hero Emblem with gentle floating animation
                    const DuwaLogo(
                      size: DuwaLogoSize.hero,
                      showWordmark: false,
                      withGlow: true,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then()
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -6,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        ),

                    const SizedBox(height: 32),

                    // Bold Wordmark
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DUWA',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E1E), Color(0xFFFFA114)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: DuwaColors.solarFlame.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'SQUAD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 500.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),

                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      'Game sessions without the group chat chaos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 500.ms),

                    const Spacer(flex: 3),

                    // Modern Neon Loading Pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 160,
                        height: 4,
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFCBD5E1),
                        child: Shimmer.fromColors(
                          baseColor: Colors.transparent,
                          highlightColor: const Color(0xFFFFA114),
                          period: const Duration(milliseconds: 1400),
                          child: Container(
                            width: 160,
                            height: 4,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF5E1E),
                                  Color(0xFFFFA114),
                                  Color(0xFFFFD280),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms),

                    const SizedBox(height: 14),

                    // Status Text with subtle breathing
                    Text(
                      widget.statusText,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 900.ms),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
