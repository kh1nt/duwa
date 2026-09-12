import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';
import '../common/bouncy_tap.dart';

/// Action Command Hub
/// Replaces formulaic identical bento boxes with a clear visual hierarchy:
/// an expressive primary action for planning a session, paired with two
/// compact, tactile utilities for joining rooms and picking games.
class HomeBentoHub extends StatelessWidget {
  final DuwaThemeData duwaTheme;
  final VoidCallback onPlanSession;
  final VoidCallback onJoinCode;
  final VoidCallback onQuickVote;
  final VoidCallback? onRandomGame;

  const HomeBentoHub({
    super.key,
    required this.duwaTheme,
    required this.onPlanSession,
    required this.onJoinCode,
    required this.onQuickVote,
    this.onRandomGame,
  });

  @override
  Widget build(BuildContext context) {
    final t = duwaTheme;
    final isDark = t.isDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Action: Plan a Game Night
          Expanded(
            flex: 11,
            child: BouncyTap(
              onTap: onPlanSession,
              scaleDown: 0.97,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: t.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: t.primaryAccent.withAlpha(isDark ? 90 : 60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Quick Host',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Plan a Game',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Schedule with squad',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Secondary Actions: Enter Code & Pick Game
          Expanded(
            flex: 10,
            child: Column(
              children: [
                // Secondary 1: Join with Code
                Expanded(
                  child: BouncyTap(
                    onTap: onJoinCode,
                    scaleDown: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: t.cardBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 8),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: t.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.vpn_key_outlined,
                              size: 16,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Join Room',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  'Enter code',
                                  style: TextStyle(
                                    color: t.textMuted,
                                    fontSize: 10.5,
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
                ),
                const SizedBox(height: 8),

                // Secondary 2: Pick Game / Ballot / Wheel
                Expanded(
                  child: BouncyTap(
                    onTap: onRandomGame ?? onQuickVote,
                    scaleDown: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: t.cardBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 8),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: t.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              onRandomGame != null ? Icons.casino_outlined : Icons.how_to_vote_outlined,
                              size: 16,
                              color: t.secondaryAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  onRandomGame != null ? 'Game Picker' : 'Game Ballot',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  'Wheel & vote',
                                  style: TextStyle(
                                    color: t.textMuted,
                                    fontSize: 10.5,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
