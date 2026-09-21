import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';

/// Atmospheric animated splash screen for DUWA celebrating the "Gamepad D" identity.
///
/// Features:
/// 1. Floating Solar Ember particles ascending gently.
/// 2. Gamepad Controller Awakening: Solar pulse shockwave & spring reveal.
/// 3. Direct Logo Relation: Sequential glowing pings on the D-Pad (+) and Action Buttons.
/// 4. Angled metallic sheen sweep across the emblem.
/// 5. Cinematic "DUWA" letter-spacing tracking expansion & Solar Flame SQUAD badge.
/// 6. Futuristic segmented telemetry energy bar with diagnostic status strings.
/// 7. Tap-to-skip with haptic response & graceful fade handoff.
class DuwaSplashScreen extends StatefulWidget {
  final DuwaThemeData duwaTheme;
  final VoidCallback onComplete;
  final Duration minDuration;
  final bool enableTapToSkip;

  const DuwaSplashScreen({
    super.key,
    required this.duwaTheme,
    required this.onComplete,
    this.minDuration = const Duration(milliseconds: 2200),
    this.enableTapToSkip = true,
  });

  @override
  State<DuwaSplashScreen> createState() => _DuwaSplashScreenState();
}

class _DuwaSplashScreenState extends State<DuwaSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final AnimationController _emberController;
  late final AnimationController _pulseController;
  late final AnimationController _sheenController;
  late final AnimationController _controllerPingController;

  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _fadeTransitionAnimation;

  Timer? _completeTimer;
  Timer? _pingTimer;
  bool _isTransitioning = false;

  final List<_EmberParticle> _particles = [];
  final math.Random _rng = math.Random();

  int _telemetryStage = 0; // 0: Init, 1: Calibrating, 2: Ready

  @override
  void initState() {
    super.initState();

    // 1. Master Timeline Controller
    _masterController = AnimationController(
      vsync: this,
      duration: widget.minDuration,
    );

    // 2. Ember Particle Ambient Motion (Continuous)
    _emberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Generate initial ember particles
    for (int i = 0; i < 26; i++) {
      _particles.add(_EmberParticle.random(_rng));
    }

    // 3. Solar Flame Ambient Radial Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // 4. Logo Sheen Sweep
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 5. Gamepad Input Diagnostics Ping (D-pad & Buttons)
    _controllerPingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo entrance scale curve
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.70, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.45, curve: Curves.linear),
      ),
    );

    // Screen exit fade curve
    _fadeTransitionAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start boot sequence
    _masterController.forward();

    // Trigger diagnostics ping at 450ms
    _pingTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        _controllerPingController.forward();
        _sheenController.forward();
        HapticFeedback.lightImpact();
      }
    });

    // Telemetry updates
    _masterController.addListener(() {
      final progress = _masterController.value;
      final newStage = progress < 0.35 ? 0 : (progress < 0.75 ? 1 : 2);
      if (newStage != _telemetryStage && mounted) {
        setState(() {
          _telemetryStage = newStage;
        });
        if (newStage == 2) {
          HapticFeedback.selectionClick();
        }
      }
    });

    // Auto complete timer
    _completeTimer = Timer(widget.minDuration, () {
      _finish();
    });
  }

  void _finish() {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _pingTimer?.cancel();
    _completeTimer?.cancel();
    widget.onComplete();
  }

  void _handleTapToSkip() {
    if (!widget.enableTapToSkip || _isTransitioning) return;
    HapticFeedback.mediumImpact();
    _finish();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _completeTimer?.cancel();
    _masterController.dispose();
    _emberController.dispose();
    _pulseController.dispose();
    _sheenController.dispose();
    _controllerPingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF080A10);
    final bgLight = const Color(0xFF0D1019);

    final telemetryText = switch (_telemetryStage) {
      0 => 'INITIALIZING SQUAD MESH // CORE v1.0',
      1 => 'CALIBRATING CONTROLLERS & D-PAD...',
      _ => 'ALL SYSTEMS SYNCED • READY TO PLAY',
    };

    return Scaffold(
      backgroundColor: bgDark,
      body: GestureDetector(
        onTap: _handleTapToSkip,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _fadeTransitionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeTransitionAnimation.value.clamp(0.0, 1.0),
              child: Stack(
                children: [
                  // 1. Ambient Background Gradient with subtle central radiance
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.15),
                          radius: 1.15,
                          colors: [
                            const Color(0xFF1E1512), // Subtle warm ember core
                            bgLight,
                            bgDark,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. Rising Solar Ember Particles Canvas
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _emberController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _EmberPainter(
                            particles: _particles,
                            progress: _emberController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Tactical Reticle & Grid Crosshairs (Corner telemetry)
                  const _TacticalHudReticles(),

                  // 4. Solar Flame Pulse Shockwaves Behind Logo
                  Align(
                    alignment: const Alignment(0.0, -0.15),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final scale = 0.90 + (_pulseController.value * 0.22);
                        final opacity = 0.25 + (_pulseController.value * 0.35);

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  DuwaColors.solarFlame.withValues(alpha: opacity * 0.45),
                                  DuwaColors.emberGold.withValues(alpha: opacity * 0.20),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 5. Central Hero Composition
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 3),

                            // --- HERO GAMEPAD D EMBLEM WITH DIRECT LOGO ANATOMY ANIMATIONS ---
                            AnimatedBuilder(
                              animation: _masterController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: child,
                                );
                              },
                              child: _GamepadLogoAnatomyWidget(
                                pingController: _controllerPingController,
                                sheenController: _sheenController,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // --- BRAND WORDMARK WITH TRACKING EXPANSION ---
                            _buildBrandWordmark(),

                            const SizedBox(height: 12),

                            // --- BRAND TAGLINE ---
                            AnimatedBuilder(
                              animation: _masterController,
                              builder: (context, child) {
                                final anim = CurvedAnimation(
                                  parent: _masterController,
                                  curve: const Interval(0.28, 0.60, curve: Curves.easeOut),
                                );
                                return Opacity(
                                  opacity: anim.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1.0 - anim.value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                'Game sessions without the group chat chaos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.duwaTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                            const Spacer(flex: 3),

                            // --- FUTURISTIC SEGMENTED TELEMETRY ENERGY BAR ---
                            AnimatedBuilder(
                              animation: _masterController,
                              builder: (context, child) {
                                final opacity = CurvedAnimation(
                                  parent: _masterController,
                                  curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
                                ).value;
                                return Opacity(
                                  opacity: opacity,
                                  child: child,
                                );
                              },
                              child: _SegmentedEnergyBar(
                                masterController: _masterController,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // --- DYNAMIC TELEMETRY STATUS TEXT ---
                            AnimatedBuilder(
                              animation: Listenable.merge([_masterController, _pulseController]),
                              builder: (context, child) {
                                final entrance = CurvedAnimation(
                                  parent: _masterController,
                                  curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
                                ).value;
                                final breathing = 0.65 + (_pulseController.value * 0.35);

                                return Opacity(
                                  opacity: (entrance * breathing).clamp(0.0, 1.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _telemetryStage == 2
                                              ? const Color(0xFF22C55E)
                                              : DuwaColors.solarFlame,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_telemetryStage == 2
                                                      ? const Color(0xFF22C55E)
                                                      : DuwaColors.solarFlame)
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        telemetryText,
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // Subtle skip prompt
                            if (widget.enableTapToSkip)
                              AnimatedBuilder(
                                animation: _masterController,
                                builder: (context, child) {
                                  final opacity = CurvedAnimation(
                                    parent: _masterController,
                                    curve: const Interval(0.50, 0.80, curve: Curves.easeOut),
                                  ).value;
                                  return Opacity(
                                    opacity: opacity * 0.30,
                                    child: child,
                                  );
                                },
                                child: const Text(
                                  'TAP TO SKIP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),

                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandWordmark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Wordmark "DUWA"
        AnimatedBuilder(
          animation: _masterController,
          builder: (context, _) {
            final tracking = Tween<double>(begin: 8.0, end: 2.5).transform(
              CurvedAnimation(
                parent: _masterController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
              ).value,
            );

            return Text(
              'DUWA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: tracking,
              ),
            );
          },
        ),

        const SizedBox(width: 10),

        // Glowing Tactical SQUAD Pill Badge
        AnimatedBuilder(
          animation: _masterController,
          builder: (context, child) {
            final anim = CurvedAnimation(
              parent: _masterController,
              curve: const Interval(0.25, 0.55, curve: Curves.easeOutBack),
            );
            return Transform.scale(
              scale: 0.7 + (anim.value * 0.3),
              child: Opacity(
                opacity: anim.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF5E1E), // Solar Flame
                  Color(0xFFFFA114), // Ember Gold
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: DuwaColors.solarFlame.withValues(alpha: 0.55),
                  blurRadius: 10,
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
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero Gamepad Logo Widget that animates the specific anatomical components
/// of the DUWA Gamepad "D" identity:
/// - Left D-Pad cross (+) activation ping
/// - Right dual action buttons (A & B) activation pings
/// - Diagonal metallic light sheen sweep across the face
class _GamepadLogoAnatomyWidget extends StatelessWidget {
  final AnimationController pingController;
  final AnimationController sheenController;

  const _GamepadLogoAnatomyWidget({
    required this.pingController,
    required this.sheenController,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 130.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Tactical Dark Squircle Base with Solar Border Glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF10131D),
              borderRadius: BorderRadius.circular(size * 0.26),
              border: Border.all(
                color: DuwaColors.solarFlame.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DuwaColors.solarFlame.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // 2. The DUWA Gamepad Logo Image
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: Image.asset(
              'assets/images/duwa_gamepad_logo.png',
              width: size * 0.82,
              height: size * 0.82,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 3. Diagonal Metallic Sheen Sweep
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: AnimatedBuilder(
              animation: sheenController,
              builder: (context, _) {
                final val = sheenController.value;
                if (val <= 0.0 || val >= 1.0) return const SizedBox.shrink();

                return Transform.translate(
                  offset: Offset((val * 2.5 - 1.25) * size, 0),
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Container(
                      width: 32,
                      height: size * 1.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. DIRECT LOGO RELATION: D-Pad (+) Controller Pulse on the left branch
          Positioned(
            left: size * 0.18,
            top: size * 0.38,
            child: AnimatedBuilder(
              animation: pingController,
              builder: (context, _) {
                // Ping triggers between 0.1 and 0.55
                final t = (pingController.value - 0.1) / 0.45;
                if (t < 0.0 || t > 1.0) return const SizedBox.shrink();

                final scale = 1.0 + (t * 1.8);
                final opacity = (1.0 - t).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF9E3D).withValues(alpha: opacity),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DuwaColors.solarFlame.withValues(alpha: opacity * 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. DIRECT LOGO RELATION: Action Buttons (A & B) Pulses on the right grip
          // Upper Action Button
          Positioned(
            right: size * 0.28,
            top: size * 0.34,
            child: AnimatedBuilder(
              animation: pingController,
              builder: (context, _) {
                // Ping triggers between 0.35 and 0.75
                final t = (pingController.value - 0.35) / 0.40;
                if (t < 0.0 || t > 1.0) return const SizedBox.shrink();

                final scale = 1.0 + (t * 1.6);
                final opacity = (1.0 - t).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: opacity),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA114).withValues(alpha: opacity * 0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Lower Action Button
          Positioned(
            right: size * 0.28,
            bottom: size * 0.34,
            child: AnimatedBuilder(
              animation: pingController,
              builder: (context, _) {
                // Ping triggers between 0.55 and 0.95
                final t = (pingController.value - 0.55) / 0.40;
                if (t < 0.0 || t > 1.0) return const SizedBox.shrink();

                final scale = 1.0 + (t * 1.6);
                final opacity = (1.0 - t).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: opacity),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E1E).withValues(alpha: opacity * 0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented Futuristic Energy Bar
class _SegmentedEnergyBar extends StatelessWidget {
  final AnimationController masterController;

  const _SegmentedEnergyBar({
    required this.masterController,
  });

  @override
  Widget build(BuildContext context) {
    const int segmentsCount = 12;
    const double barWidth = 180.0;
    const double segmentWidth = (barWidth - (segmentsCount - 1) * 3) / segmentsCount;

    return AnimatedBuilder(
      animation: masterController,
      builder: (context, _) {
        final progress = masterController.value;
        final filledSegments = (progress * segmentsCount).floor();

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF222838),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(segmentsCount, (index) {
              final isFilled = index <= filledSegments;
              final isCurrent = index == filledSegments;

              return Container(
                width: segmentWidth,
                height: 5,
                margin: EdgeInsets.only(right: index == segmentsCount - 1 ? 0 : 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isFilled
                      ? (isCurrent
                          ? const Color(0xFFFFA114)
                          : DuwaColors.solarFlame)
                      : const Color(0xFF1C2232),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: DuwaColors.solarFlame.withValues(
                              alpha: isCurrent ? 0.8 : 0.4,
                            ),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Subtle Tactical Reticle & Grid Crosshairs
class _TacticalHudReticles extends StatelessWidget {
  const _TacticalHudReticles();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _reticleCorner(top: true, left: true),
                  _reticleCorner(top: true, left: false),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _reticleCorner(top: false, left: true),
                  _reticleCorner(top: false, left: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reticleCorner({required bool top, required bool left}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5)
              : BorderSide.none,
          left: left
              ? BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Ambient Floating Solar Ember Particle model
class _EmberParticle {
  double x; // 0.0 to 1.0 (screen width fraction)
  double y; // 0.0 to 1.0 (screen height fraction)
  double radius;
  double speed;
  double swayAmplitude;
  double swayFrequency;
  double alpha;
  Color color;

  _EmberParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.alpha,
    required this.color,
  });

  factory _EmberParticle.random(math.Random rng) {
    final colors = [
      const Color(0xFFFF5E1E), // Solar Flame
      const Color(0xFFFFA114), // Ember Gold
      const Color(0xFFFF7A3D), // Warm Amber
      const Color(0xFFFFC078), // Golden spark
    ];

    return _EmberParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 1.2 + rng.nextDouble() * 2.2,
      speed: 0.08 + rng.nextDouble() * 0.12,
      swayAmplitude: 0.015 + rng.nextDouble() * 0.025,
      swayFrequency: 2.0 + rng.nextDouble() * 4.0,
      alpha: 0.25 + rng.nextDouble() * 0.55,
      color: colors[rng.nextInt(colors.length)],
    );
  }
}

/// Custom Painter for Rising Solar Embers
class _EmberPainter extends CustomPainter {
  final List<_EmberParticle> particles;
  final double progress;

  _EmberPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Calculate animated vertical position (ascending upward)
      final currentY = ((p.y - (progress * p.speed)) % 1.0) * size.height;
      // Calculate gentle horizontal sine sway
      final currentX =
          (p.x + math.sin((progress * 2 * math.pi * p.swayFrequency) + (p.y * 10)) *
                  p.swayAmplitude) *
              size.width;

      // Subtle alpha fade near bottom and top edges
      final edgeFade = math.sin((currentY / size.height).clamp(0.0, 1.0) * math.pi);
      final effectiveAlpha = (p.alpha * edgeFade).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: effectiveAlpha)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(currentX, currentY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
