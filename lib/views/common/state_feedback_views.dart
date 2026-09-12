import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/duwa_colors.dart';
import 'bouncy_tap.dart';
import 'duwa_buttons.dart';
import 'duwa_cards.dart';
import 'duwa_mascot.dart';
import 'duwa_shimmer.dart';

class EmptyStateWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MascotMood mascotMood;

  const EmptyStateWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.mascotMood = MascotMood.sleeping,
  });

  factory EmptyStateWidget.gameNights({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      emoji: '🎮',
      title: 'No squad sessions planned yet',
      subtitle: 'Assemble your squad and schedule your next session! Duwi is ready.',
      actionLabel: 'Plan Session',
      onAction: onCreate,
      mascotMood: MascotMood.sleeping,
    );
  }

  factory EmptyStateWidget.groups({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      emoji: '👥',
      title: 'No squads yet',
      subtitle: 'Create a squad and invite your friends to start playing!',
      actionLabel: 'Create Squad',
      onAction: onCreate,
      mascotMood: MascotMood.idle,
    );
  }

  factory EmptyStateWidget.sessions({VoidCallback? onCreate}) {
    return EmptyStateWidget(
      emoji: '📅',
      title: 'No game sessions here',
      subtitle: 'Schedule a session with your squad to vote on games, confirm players, and coordinate snacks.',
      actionLabel: 'Plan Session',
      onAction: onCreate,
      mascotMood: MascotMood.idle,
    );
  }

  factory EmptyStateWidget.notifications() {
    return const EmptyStateWidget(
      emoji: '✨',
      title: 'All quiet here',
      subtitle: 'No new updates right now. Check back when the session starts!',
      mascotMood: MascotMood.idle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clean Icon Illustration
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(165),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              BouncyTap(
                onTap: onAction,
                child: DuwaButton(
                  label: actionLabel!,
                  icon: Icons.add,
                  onPressed: onAction,
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeletonView extends StatelessWidget {
  const LoadingSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Playful Mascot Loading Header
        Center(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Summoning the squad...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Shimmering skeleton cards
        DuwaShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBlock(height: 156, borderRadius: 24),
              const SizedBox(height: 20),
              const ShimmerBlock(width: 140, height: 18, borderRadius: 8),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: ShimmerBlock(height: 88, borderRadius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBlock(height: 88, borderRadius: 18)),
                ],
              ),
              const SizedBox(height: 22),
              const ShimmerBlock(width: 180, height: 18, borderRadius: 8),
              const SizedBox(height: 14),
              const ShimmerBlock(height: 72, borderRadius: 18),
              const SizedBox(height: 10),
              const ShimmerBlock(height: 72, borderRadius: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class ErrorFeedbackWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const ErrorFeedbackWidget({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'Couldn\'t load the session details. Check connection and retry.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DuwaColors.errorRed.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: DuwaColors.errorRed,
                size: 34,
              ),
            ).animate().shake(duration: 500.ms, curve: Curves.easeInOutCubic),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: DuwaColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            BouncyTap(
              onTap: onRetry,
              child: DuwaButton(
                label: 'Retry',
                icon: Icons.refresh,
                variant: DuwaButtonVariant.outline,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessConfirmationWidget extends StatelessWidget {
  final String gameTitle;
  final String dateDisplay;
  final String timeDisplay;
  final int goingCount;
  final VoidCallback onOpenSession;
  final VoidCallback onInviteMore;

  const SuccessConfirmationWidget({
    super.key,
    required this.gameTitle,
    required this.dateDisplay,
    required this.timeDisplay,
    required this.goingCount,
    required this.onOpenSession,
    required this.onInviteMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981),
                width: 2.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 42,
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 450.ms),
          const SizedBox(height: 20),
          const Text(
            'Session is set!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your squad is assembled and ready! 🎮',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DuwaColors.blueIris,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Mini Card
          DuwaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gameTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const DuwaBadge(
                      label: 'Confirmed',
                      backgroundColor: Color(0xFF064E3B),
                      textColor: DuwaColors.successGreen,
                      icon: Icons.check,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: DuwaColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '$dateDisplay · $timeDisplay',
                      style: const TextStyle(fontSize: 13, color: DuwaColors.grayFlash),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: DuwaColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '$goingCount players going',
                      style: const TextStyle(fontSize: 13, color: DuwaColors.grayFlash),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          BouncyTap(
            onTap: onOpenSession,
            child: DuwaButton(
              label: 'Open Session',
              icon: Icons.arrow_forward,
              isFullWidth: true,
              onPressed: onOpenSession,
            ),
          ),
          const SizedBox(height: 12),
          BouncyTap(
            onTap: onInviteMore,
            child: DuwaButton(
              label: 'Invite Friends',
              icon: Icons.share,
              variant: DuwaButtonVariant.secondary,
              isFullWidth: true,
              onPressed: onInviteMore,
            ),
          ),
        ],
      ),
    );
  }
}
