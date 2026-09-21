import 'package:flutter/material.dart';

/// Pixel-perfect vector representation of the modern 4-color Gmail envelope logo.
/// Based on Google Workspace geometric design guidelines.
class GmailLogoWidget extends StatelessWidget {
  final double size;

  const GmailLogoWidget({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (18 / 24),
      child: CustomPaint(
        painter: _GmailLogoPainter(),
      ),
    );
  }
}

class _GmailLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 18.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Left Pillar (Google Blue #4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(2.0, 5.5)
      ..lineTo(6.5, 9.0)
      ..lineTo(6.5, 18.0)
      ..lineTo(3.5, 18.0)
      ..arcToPoint(const Offset(2.0, 16.5), radius: const Radius.circular(1.5))
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Right Pillar (Google Green #34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(22.0, 5.5)
      ..lineTo(17.5, 9.0)
      ..lineTo(17.5, 18.0)
      ..lineTo(20.5, 18.0)
      ..arcToPoint(const Offset(22.0, 16.5), radius: const Radius.circular(1.5), clockwise: false)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Top Left Shoulder (Google Red #EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final leftShoulderPath = Path()
      ..moveTo(2.0, 5.5)
      ..lineTo(2.0, 3.5)
      ..arcToPoint(const Offset(3.8, 2.2), radius: const Radius.circular(1.8))
      ..lineTo(6.5, 4.3)
      ..lineTo(6.5, 9.0)
      ..close();
    canvas.drawPath(leftShoulderPath, redPaint);

    // 4. Center Fold (Google Red #EA4335 with #C5221F shadow fold)
    final centerRoofPath = Path()
      ..moveTo(6.5, 4.3)
      ..lineTo(12.0, 8.5)
      ..lineTo(17.5, 4.3)
      ..lineTo(17.5, 9.0)
      ..lineTo(12.0, 13.2)
      ..lineTo(6.5, 9.0)
      ..close();
    canvas.drawPath(centerRoofPath, redPaint);

    // 5. Top Right Shoulder (Google Yellow #FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final rightShoulderPath = Path()
      ..moveTo(17.5, 9.0)
      ..lineTo(22.0, 5.5)
      ..lineTo(22.0, 3.5)
      ..arcToPoint(const Offset(20.2, 2.2), radius: const Radius.circular(1.8), clockwise: false)
      ..lineTo(17.5, 4.3)
      ..close();
    canvas.drawPath(rightShoulderPath, yellowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
