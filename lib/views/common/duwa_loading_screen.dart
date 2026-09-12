import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/duwa_theme.dart';
import 'duwa_logo.dart';

/// Market-competitive animated loading & splash screen for DUWA.
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
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<DuwaLoadingScreen> createState() => _DuwaLoadingScreenState();
}

class _DuwaLoadingScreenState extends State<DuwaLoadingScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.onFinished != null) {
      Future.delayed(widget.duration, widget.onFinished);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Logo
                const DuwaLogo(
                  size: DuwaLogoSize.large,
                  showWordmark: false,
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1.05, 1.05),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 24),

                // Brand Name
                Text(
                  'DUWA',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 6),

                // Slogan
                Text(
                  'Game sessions without the group chat chaos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

                const Spacer(flex: 2),

                // Shimmer progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Shimmer.fromColors(
                    baseColor: t.surfaceHighest,
                    highlightColor: t.primaryAccent.withAlpha(90),
                    child: Container(
                      width: 140,
                      height: 4,
                      color: t.surfaceHighest,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Status text
                Text(
                  widget.statusText,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 800.ms),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
