import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';

/// An overlay widget that bursts celebratory gaming confetti across the screen
/// when users RSVP "Going", win a game vote, or create a new game night.
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final ConfettiController confettiController;

  const CelebrationOverlay({
    super.key,
    required this.child,
    required this.confettiController,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center-top blast
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: widget.confettiController,
            blastDirection: pi / 2, // downwards
            maxBlastForce: 18,
            minBlastForce: 6,
            emissionFrequency: 0.05,
            numberOfParticles: 26,
            gravity: 0.25,
            colors: const [
              DuwaColors.solarFlame,
              DuwaColors.ionMint,
              DuwaColors.lightPrimary,
              DuwaColors.hyperIndigo,
              Color(0xFFFFD166),
              Color(0xFF06D6A0),
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper function to show a celebratory snackbar with gamified flair.
void showGameCelebrationSnackBar({
  required BuildContext context,
  required String title,
  required String subtitle,
  String emoji = '🎉',
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      duration: const Duration(seconds: 3),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151922).withAlpha(245),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DuwaColors.mysticPrimary.withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: DuwaColors.mysticPrimary.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DuwaColors.mysticPrimary.withAlpha(35),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DuwaColors.mysticOnSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
