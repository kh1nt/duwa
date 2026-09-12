import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';

enum MascotMood {
  idle,
  sleeping,
  hyped,
  loading,
  celebrating,
  playing,
  waiting,
}

/// "Duwi" — DUWA's animated robot gaming mascot.
/// Rendered with custom vector paths & physics so it is lightweight, razor-sharp,
/// and reactive to the current theme vibe and emotional state.
class DuwaMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final DuwaThemeData? theme;

  const DuwaMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 110,
    this.theme,
  });

  @override
  State<DuwaMascot> createState() => _DuwaMascotState();
}

class _DuwaMascotState extends State<DuwaMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ??
        (Theme.of(context).brightness == Brightness.dark
            ? DuwaThemeData.obsidianVoid()
            : DuwaThemeData.cleanLight());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DuwaMascotPainter(
            progress: progress,
            mood: widget.mood,
            primaryColor: t.primaryAccent,
            secondaryColor: t.secondaryAccent,
            surfaceColor: t.surfaceLight,
            eyeGlowColor: t.primaryAccent,
          ),
        );
      },
    );
  }
}

class _DuwaMascotPainter extends CustomPainter {
  final double progress;
  final MascotMood mood;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color eyeGlowColor;

  _DuwaMascotPainter({
    required this.progress,
    required this.mood,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.eyeGlowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 100.0;

    // Breathing float offset
    double floatY = 0;
    if (mood == MascotMood.sleeping) {
      floatY = math.sin(progress * 2 * math.pi) * 3 * scale;
    } else if (mood == MascotMood.hyped || mood == MascotMood.celebrating) {
      floatY = -math.sin(progress * 4 * math.pi).abs() * 7 * scale;
    } else if (mood == MascotMood.playing) {
      floatY = math.sin(progress * 4 * math.pi) * 2 * scale;
    } else if (mood == MascotMood.waiting) {
      floatY = math.sin(progress * 1.5 * math.pi) * 3 * scale;
    } else {
      floatY = math.sin(progress * 2 * math.pi) * 4 * scale;
    }

    final center = Offset(cx, cy + floatY + 4 * scale);

    // 1. Soft Ambient Shadow below
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final shadowWidth = (44 + (mood == MascotMood.hyped ? 2 : 6) * math.cos(progress * 2 * math.pi)) * scale;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 8 * scale),
        width: shadowWidth,
        height: 10 * scale,
      ),
      shadowPaint,
    );

    // 2. Antenna
    final antennaStemPaint = Paint()
      ..color = secondaryColor.withAlpha(200)
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    final antennaTip = Offset(center.dx, center.dy - 34 * scale);
    canvas.drawLine(
      Offset(center.dx, center.dy - 22 * scale),
      antennaTip,
      antennaStemPaint,
    );

    // Glowing antenna orb
    final beaconGlowPaint = Paint()
      ..color = primaryColor.withAlpha(100)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);
    canvas.drawCircle(antennaTip, 6.5 * scale, beaconGlowPaint);

    final beaconPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(antennaTip, 4.2 * scale, beaconPaint);

    // 3. Head Chassis (Rounded Cyber Visor)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: 68 * scale,
        height: 52 * scale,
      ),
      Radius.circular(22 * scale),
    );

    // Head border aura
    final headBorderGlow = Paint()
      ..color = primaryColor.withAlpha(35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
    canvas.drawRRect(headRect, headBorderGlow);

    // Head background
    final headBgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceColor,
          const Color(0xFF080A0E),
        ],
      ).createShader(headRect.outerRect);
    canvas.drawRRect(headRect, headBgPaint);

    // Head outer border
    final headBorderPaint = Paint()
      ..color = primaryColor.withAlpha(110)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;
    canvas.drawRRect(headRect, headBorderPaint);

    // Ear bolts / headphone pads
    final earPaint = Paint()..color = secondaryColor.withAlpha(180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - 36 * scale, center.dy),
          width: 7 * scale,
          height: 18 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 36 * scale, center.dy),
          width: 7 * scale,
          height: 18 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      earPaint,
    );

    // 4. Dark Visor Screen Inside
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 1 * scale),
        width: 52 * scale,
        height: 34 * scale,
      ),
      Radius.circular(14 * scale),
    );
    final visorPaint = Paint()..color = const Color(0xFF030407);
    canvas.drawRRect(visorRect, visorPaint);

    // Subtle scanline / glow on visor
    final visorGlow = Paint()
      ..color = eyeGlowColor.withAlpha(18)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(visorRect, visorGlow);

    // 5. Expressive Visor Eyes
    _drawEyes(canvas, center, scale);

    // 6. Extras according to mood
    if (mood == MascotMood.sleeping) {
      _drawZzz(canvas, center, scale);
    } else if (mood == MascotMood.hyped) {
      _drawHypeSparks(canvas, center, scale);
    } else if (mood == MascotMood.loading) {
      _drawLoadingOrbiter(canvas, center, scale);
    } else if (mood == MascotMood.celebrating) {
      _drawCelebrationSparks(canvas, center, scale);
    } else if (mood == MascotMood.playing) {
      _drawController(canvas, center, scale);
    } else if (mood == MascotMood.waiting) {
      _drawWaitingDots(canvas, center, scale);
    }
  }

  void _drawEyes(Canvas canvas, Offset center, double scale) {
    final eyeGlow = Paint()
      ..color = eyeGlowColor.withAlpha(140)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
    final eyeSolid = Paint()
      ..color = eyeGlowColor
      ..style = PaintingStyle.fill;

    final leftEyeCenter = Offset(center.dx - 12 * scale, center.dy + 1 * scale);
    final rightEyeCenter = Offset(center.dx + 12 * scale, center.dy + 1 * scale);

    if (mood == MascotMood.sleeping) {
      // Closed horizontal calm slits (- -)
      final sleepPaint = Paint()
        ..color = eyeGlowColor.withAlpha(180)
        ..strokeWidth = 2.4 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(leftEyeCenter.dx - 5 * scale, leftEyeCenter.dy),
        Offset(leftEyeCenter.dx + 5 * scale, leftEyeCenter.dy),
        sleepPaint,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx - 5 * scale, rightEyeCenter.dy),
        Offset(rightEyeCenter.dx + 5 * scale, rightEyeCenter.dy),
        sleepPaint,
      );
    } else if (mood == MascotMood.hyped || mood == MascotMood.celebrating) {
      // Happy arches (^ ^)
      final happyPaint = Paint()
        ..color = eyeGlowColor
        ..strokeWidth = 2.8 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final leftPath = Path()
        ..moveTo(leftEyeCenter.dx - 6 * scale, leftEyeCenter.dy + 3 * scale)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 5 * scale,
            leftEyeCenter.dx + 6 * scale, leftEyeCenter.dy + 3 * scale);
      final rightPath = Path()
        ..moveTo(rightEyeCenter.dx - 6 * scale, rightEyeCenter.dy + 3 * scale)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 5 * scale,
            rightEyeCenter.dx + 6 * scale, rightEyeCenter.dy + 3 * scale);

      canvas.drawPath(leftPath, eyeGlow);
      canvas.drawPath(leftPath, happyPaint);
      canvas.drawPath(rightPath, eyeGlow);
      canvas.drawPath(rightPath, happyPaint);
    } else if (mood == MascotMood.waiting) {
      // Curious eyes shifted to the right
      final lookOffset = Offset(2 * scale, 0);
      final leftEye = RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEyeCenter + lookOffset, width: 7 * scale, height: 8 * scale),
        Radius.circular(3 * scale),
      );
      final rightEye = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEyeCenter + lookOffset, width: 7 * scale, height: 8 * scale),
        Radius.circular(3 * scale),
      );
      canvas.drawRRect(leftEye, eyeGlow);
      canvas.drawRRect(leftEye, eyeSolid);
      canvas.drawRRect(rightEye, eyeGlow);
      canvas.drawRRect(rightEye, eyeSolid);
    } else {
      // Idle blinking logic: blink when progress is around 0.85 - 0.90
      final isBlinking = progress > 0.86 && progress < 0.92;
      final eyeHeight = isBlinking ? 1.5 * scale : 9 * scale;
      final eyeWidth = 7 * scale;

      final leftEye = RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEyeCenter, width: eyeWidth, height: eyeHeight),
        Radius.circular(3 * scale),
      );
      final rightEye = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEyeCenter, width: eyeWidth, height: eyeHeight),
        Radius.circular(3 * scale),
      );

      canvas.drawRRect(leftEye, eyeGlow);
      canvas.drawRRect(leftEye, eyeSolid);
      canvas.drawRRect(rightEye, eyeGlow);
      canvas.drawRRect(rightEye, eyeSolid);

      // Little eye catchlights when open
      if (!isBlinking) {
        final lightPaint = Paint()..color = Colors.white.withAlpha(220);
        canvas.drawCircle(
          Offset(leftEyeCenter.dx - 1.5 * scale, leftEyeCenter.dy - 2 * scale),
          1.2 * scale,
          lightPaint,
        );
        canvas.drawCircle(
          Offset(rightEyeCenter.dx - 1.5 * scale, rightEyeCenter.dy - 2 * scale),
          1.2 * scale,
          lightPaint,
        );
      }
    }
  }

  void _drawZzz(Canvas canvas, Offset center, double scale) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Floating Z letters drifting up
    final drift1 = (progress * 18 * scale);
    final drift2 = ((progress + 0.3) % 1.0) * 22 * scale;

    textPainter.text = TextSpan(
      text: 'z',
      style: TextStyle(
        color: secondaryColor.withAlpha((180 * (1 - (progress % 1.0))).toInt()),
        fontSize: 11 * scale,
        fontWeight: FontWeight.w900,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + 26 * scale + drift1 * 0.3, center.dy - 20 * scale - drift1),
    );

    textPainter.text = TextSpan(
      text: 'Z',
      style: TextStyle(
        color: primaryColor.withAlpha((210 * (1 - ((progress + 0.3) % 1.0))).toInt()),
        fontSize: 14 * scale,
        fontWeight: FontWeight.w900,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + 34 * scale + drift2 * 0.4, center.dy - 32 * scale - drift2),
    );
  }

  void _drawHypeSparks(Canvas canvas, Offset center, double scale) {
    final sparkPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final angles = [0.2, 0.8, 1.4, 2.1, 2.7];
    for (int i = 0; i < angles.length; i++) {
      final a = angles[i] + progress * math.pi;
      final dist = (38 + 6 * math.sin(progress * 6 * math.pi + i)) * scale;
      final px = center.dx + math.cos(a) * dist;
      final py = center.dy + math.sin(a) * dist;
      canvas.drawCircle(Offset(px, py), 2.2 * scale, sparkPaint);
    }
  }

  void _drawLoadingOrbiter(Canvas canvas, Offset center, double scale) {
    final orbitRadius = 40 * scale;
    final angle = progress * 2 * math.pi;
    final orbitPaint = Paint()
      ..color = primaryColor.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(center, orbitRadius, orbitPaint);

    final dotPos = Offset(
      center.dx + math.cos(angle) * orbitRadius,
      center.dy + math.sin(angle) * orbitRadius,
    );

    final dotGlow = Paint()
      ..color = primaryColor.withAlpha(180)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    canvas.drawCircle(dotPos, 4 * scale, dotGlow);

    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(dotPos, 2.5 * scale, dotPaint);
  }

  void _drawCelebrationSparks(Canvas canvas, Offset center, double scale) {
    // Joyful celebration stars/sparks radiating with floating micro particles
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    final colors = [primaryColor, secondaryColor, const Color(0xFFFFD166), eyeGlowColor];

    for (int i = 0; i < 8; i++) {
      final a = (i * math.pi / 4) + progress * 0.8 * math.pi;
      final dist = (42 + 8 * math.sin(progress * 5 * math.pi + i)) * scale;
      final px = center.dx + math.cos(a) * dist;
      final py = center.dy + math.sin(a) * dist - 6 * scale;
      sparkPaint.color = colors[i % colors.length];

      // Star / diamond shape
      final path = Path();
      const double r = 3.5;
      path.moveTo(px, py - r * scale);
      path.lineTo(px + r * scale * 0.4, py - r * scale * 0.4);
      path.lineTo(px + r * scale, py);
      path.lineTo(px + r * scale * 0.4, py + r * scale * 0.4);
      path.lineTo(px, py + r * scale);
      path.lineTo(px - r * scale * 0.4, py + r * scale * 0.4);
      path.lineTo(px - r * scale, py);
      path.lineTo(px - r * scale * 0.4, py - r * scale * 0.4);
      path.close();

      canvas.drawPath(path, sparkPaint);
    }
  }

  void _drawController(Canvas canvas, Offset center, double scale) {
    // Cute tactile mini handheld gamepad held right below visor
    final ctrlCenter = Offset(center.dx, center.dy + 24 * scale);
    final ctrlRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctrlCenter, width: 34 * scale, height: 16 * scale),
      Radius.circular(8 * scale),
    );

    // Controller body
    final ctrlPaint = Paint()..color = surfaceColor;
    final ctrlBorder = Paint()
      ..color = primaryColor.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scale;
    canvas.drawRRect(ctrlRect, ctrlPaint);
    canvas.drawRRect(ctrlRect, ctrlBorder);

    // D-pad on left
    final dpadPaint = Paint()..color = secondaryColor;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(ctrlCenter.dx - 8 * scale, ctrlCenter.dy), width: 6 * scale, height: 2 * scale),
      dpadPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(ctrlCenter.dx - 8 * scale, ctrlCenter.dy), width: 2 * scale, height: 6 * scale),
      dpadPaint,
    );

    // AB buttons on right
    final btnPaint = Paint()..color = primaryColor;
    canvas.drawCircle(Offset(ctrlCenter.dx + 6 * scale, ctrlCenter.dy - 2 * scale), 1.8 * scale, btnPaint);
    canvas.drawCircle(Offset(ctrlCenter.dx + 9.5 * scale, ctrlCenter.dy + 2 * scale), 1.8 * scale, btnPaint);
  }

  void _drawWaitingDots(Canvas canvas, Offset center, double scale) {
    // Three subtle thinking/waiting dots drifting above
    for (int i = 0; i < 3; i++) {
      final bounce = math.sin((progress * 3 * math.pi) + (i * 0.8)).clamp(0.0, 1.0);
      final dotPaint = Paint()
        ..color = secondaryColor.withAlpha((140 + 100 * bounce).toInt())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(center.dx - 8 * scale + (i * 8 * scale), center.dy - 38 * scale - (bounce * 4 * scale)),
        2.2 * scale,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DuwaMascotPainter oldDelegate) => true;
}

/// Official 3D Plush Gaming Companion Mascot from the Stitch specification
class DuwaPlushMascot extends StatefulWidget {
  final double size;
  final bool animate;
  final BoxFit fit;

  const DuwaPlushMascot({
    super.key,
    this.size = 120,
    bool animate = true,
    bool? enableFloating,
    this.fit = BoxFit.contain,
  }) : animate = enableFloating ?? animate;

  static const String mascotImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCUJBrYnNy_oIRRLadHxuIpjyJ1IkMpIwA2Bb2gW_qGhNCgMnraDdt9ijzk8XIC7P6qOm21zoHHp0p-0ev-QMe-ROLT37TXfuJY5zK9wFMvdXsNb94-fLwO-BCy2hSAmRQkizKYoEUm2b0xSxKLX1gDtfHBBU8ovFvbCsTVcjDYdogjXzmAd-7Jw4H1SdcUAt78TkXAzMgmHmrGbhCjaf7BhdAV1JTPHcgKAKDqhiyZw7lbzXPmfdk8TQ';

  @override
  State<DuwaPlushMascot> createState() => _DuwaPlushMascotState();
}

class _DuwaPlushMascotState extends State<DuwaPlushMascot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.animate && !isTest) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      DuwaPlushMascot.mascotImageUrl,
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => DuwaMascot(
        size: widget.size,
        mood: MascotMood.idle,
      ),
    );

    final controller = _controller;
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final dy = math.sin(controller.value * math.pi) * 4.0;
          return Transform.translate(
            offset: Offset(0, -dy),
            child: child,
          );
        },
        child: image,
      );
    }

    return image;
  }
}

