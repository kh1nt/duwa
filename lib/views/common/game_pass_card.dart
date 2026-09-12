import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import 'bouncy_tap.dart';
import 'player_avatar.dart';

/// Architectural Session Card:
/// Elegant, high-craft game night card with real game header artwork,
/// confident typography, squad attendance tally, and an interactive RSVP toggle.
class GamePassCard extends StatelessWidget {
  final GameNightModel session;
  final DuwaThemeData duwaTheme;
  final VoidCallback onTap;
  final ValueChanged<RSVPStatus>? onRsvpChanged;
  final String? currentUserId;
  final String? currentUserName;
  final bool isCompact;

  const GamePassCard({
    super.key,
    required this.session,
    required this.duwaTheme,
    required this.onTap,
    this.onRsvpChanged,
    this.currentUserId,
    this.currentUserName,
    this.isCompact = false,
  });

  RSVPStatus? get _myRsvp {
    final uid = currentUserId ?? 'p1';
    for (final p in session.players) {
        final normalizedName = p.name.replaceAll(' (You)', '').trim().toLowerCase();
        if (p.id == uid || p.id == 'p1' || p.name == 'You' || p.name.contains('(You)' ) ||
          (currentUserName != null && normalizedName == currentUserName!.trim().toLowerCase())) {
        return p.rsvp;
      }
    }
    return null;
  }

  (Color, Color) _getGameAtmosphere() {
    if (session.status == GameNightStatus.voting) {
      return (const Color(0xFF4F46E5), const Color(0xFF1E1B4B));
    }
    final title = (session.selectedGame?.title ?? session.title).toLowerCase();
    if (title.contains('val') || title.contains('apex')) {
      return (const Color(0xFFE11D48), const Color(0xFF1C0A10));
    }
    if (title.contains('dota') || title.contains('smash')) {
      return (const Color(0xFFDC2626), const Color(0xFF1C0808));
    }
    if (title.contains('catan')) {
      return (const Color(0xFFD97706), const Color(0xFF1E1206));
    }
    if (title.contains('overcooked')) {
      return (const Color(0xFFEA580C), const Color(0xFF1E0D06));
    }
    return (duwaTheme.primaryAccent, const Color(0xFF0F1422));
  }

  String _getUrgencyText() {
    if (session.status == GameNightStatus.voting) return 'VOTING';
    final scheduled = session.scheduledDateTime;
    if (scheduled != null) {
      final now = DateTime.now();
      final diff = scheduled.difference(now);
      if (diff.isNegative && diff.inHours.abs() < 4) return 'LIVE NOW';
      if (scheduled.year == now.year && scheduled.month == now.month && scheduled.day == now.day) {
        return 'TONIGHT';
      }
      if (scheduled.difference(DateTime(now.year, now.month, now.day)).inDays == 1) {
        return 'TOMORROW';
      }
    }
    return session.formattedDate.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (duwaTheme.isCozy) {
      return _buildCozyCard(context);
    }
    final (glowColor, baseBg) = _getGameAtmosphere();
    final isDark = !duwaTheme.isCleanLight;
    final coverUrl = session.selectedGame?.displayCoverUrl;
    final urgency = _getUrgencyText();

    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: duwaTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: duwaTheme.cardBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(90) : Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAME BANNER IMAGE OR ARTFUL SCRIM
            SizedBox(
              height: isCompact ? 100 : 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => _buildFallbackHeader(glowColor, baseBg),
                    )
                  else
                    _buildFallbackHeader(glowColor, baseBg),

                  // Subtle dark gradient scrim
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(30),
                          Colors.black.withAlpha(120),
                          Colors.black.withAlpha(220),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Header Badges Overlay
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withAlpha(30)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (urgency == 'TONIGHT' || urgency == 'LIVE NOW') ...[
                                    _PulseDot(color: DuwaColors.solarFlame),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    urgency,
                                    style: TextStyle(
                                      color: urgency == 'TONIGHT' || urgency == 'LIVE NOW'
                                          ? DuwaColors.solarFlame
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              session.group.name,
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.selectedGame?.title ?? session.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.formattedDate} · ${session.formattedTime}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CARD BODY: ATTENDANCE & RSVP
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarGroup(
                        players: session.players,
                        maxVisible: 4,
                        radius: 12,
                        showStatusDot: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.goingCount} going',
                        style: TextStyle(
                          color: duwaTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (session.maybeCount > 0)
                        Text(
                          ' · ${session.maybeCount} maybe',
                          style: TextStyle(
                            color: duwaTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: duwaTheme.textMuted,
                      ),
                    ],
                  ),

                  if (!isCompact && onRsvpChanged != null) ...[
                    const SizedBox(height: 12),
                    _buildRsvpRow(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHeader(Color glowColor, Color baseBg) {
    return Container(
      color: baseBg,
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white.withAlpha(20),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildRsvpRow() {
    final current = _myRsvp;
    final options = [
      (RSVPStatus.going, "I'm In", Icons.check_circle_rounded, DuwaColors.ionMint),
      (RSVPStatus.maybe, 'Maybe', Icons.help_outline_rounded, DuwaColors.emberGold),
      (RSVPStatus.cantGo, "Can't Go", Icons.close_rounded, const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: duwaTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: duwaTheme.cardBorder),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = current == opt.$1;
          return Expanded(
            child: BouncyTap(
              onTap: () {
                HapticFeedback.selectionClick();
                onRsvpChanged?.call(opt.$1);
              },
              scaleDown: 0.94,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? duwaTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isSelected ? Border.all(color: opt.$4.withAlpha(140)) : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: opt.$4.withAlpha(28),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        opt.$3,
                        size: 12,
                        color: isSelected ? opt.$4 : duwaTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        color: isSelected ? duwaTheme.textPrimary : duwaTheme.textMuted,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      child: Text(opt.$2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCozyCard(BuildContext context) {
    final t = duwaTheme;
    final coverUrl = session.selectedGame?.displayCoverUrl;
    final timeStr = session.timeFormatted.isNotEmpty ? session.timeFormatted : 'Tonight';
    final dateStr = _getUrgencyText();
    final current = _myRsvp;
    final isGoing = current == RSVPStatus.going;

    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: t.cardBorder, width: 1.0),
          boxShadow: DuwaTheme.cozyShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Date/Time badge + Voice Chat indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: t.surfaceLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$dateStr • $timeStr',
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.headphones_rounded, size: 14, color: t.secondaryAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Voice Chat',
                      style: TextStyle(
                        color: t.secondaryAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle row: Game thumbnail + Title & subtitle
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: coverUrl != null && coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: t.secondaryContainer,
                              alignment: Alignment.center,
                              child: Text(session.selectedGame?.emoji ?? '🎮', style: const TextStyle(fontSize: 22)),
                            ),
                          )
                        : Container(
                            color: t.secondaryContainer,
                            alignment: Alignment.center,
                            child: Text(session.selectedGame?.emoji ?? '🎮', style: const TextStyle(fontSize: 22)),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.selectedGame?.title ?? session.title,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session.food?.title.isNotEmpty == true
                            ? session.food!.title
                            : '${session.group.name} squad gathering',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: t.cardBorder.withAlpha(120)),
            const SizedBox(height: 10),

            // Bottom row: Avatar stack + RSVP status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AvatarGroup(players: session.players, maxVisible: 3, radius: 12),
                    const SizedBox(width: 8),
                    Text(
                      '${session.goingCount} joined',
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (onRsvpChanged != null)
                  BouncyTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final next = isGoing ? RSVPStatus.cantGo : RSVPStatus.going;
                      onRsvpChanged?.call(next);
                    },
                    scaleDown: 0.93,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGoing ? const Color(0xFFDCFCE7) : t.surfaceLight,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isGoing ? const Color(0xFF86EFAC) : Colors.transparent,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isGoing ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isGoing ? const Color(0xFF16A34A) : t.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isGoing ? "I'm In" : 'RSVP',
                            style: TextStyle(
                              color: isGoing ? const Color(0xFF15803D) : t.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle ambient breathing indicator dot for live / urgent sessions.
class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.45 + (0.55 * _controller.value);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((opacity * 255).round()),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha((opacity * 150).round()),
                blurRadius: 3,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

