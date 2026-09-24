import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import 'bouncy_tap.dart';
import 'player_avatar.dart';

/// The primary hero card on the home screen.
/// Designed with high visual hierarchy, clean editorial typography,
/// tactile attendance overview, and an immediate 1-tap RSVP bar.
class HeroSessionMarquee extends StatefulWidget {
  final GameNightModel? session;
  final DuwaThemeData duwaTheme;
  final VoidCallback onOpenSession;
  final VoidCallback onCreateSession;
  final ValueChanged<RSVPStatus>? onRsvpChanged;
  final String? currentUserId;
  final String? currentUserName;

  const HeroSessionMarquee({
    super.key,
    required this.session,
    required this.duwaTheme,
    required this.onOpenSession,
    required this.onCreateSession,
    this.onRsvpChanged,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<HeroSessionMarquee> createState() => _HeroSessionMarqueeState();
}

class _HeroSessionMarqueeState extends State<HeroSessionMarquee> {
  RSVPStatus? _optimisticRsvp;

  @override
  void didUpdateWidget(HeroSessionMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session?.id != widget.session?.id) {
      _optimisticRsvp = null;
    }
  }

  RSVPStatus? get _myRsvp {
    if (_optimisticRsvp != null) return _optimisticRsvp;
    if (widget.session == null) return null;
    final uid = widget.currentUserId ?? 'p1';
    for (final p in widget.session!.players) {
      final normalizedName = p.name.replaceAll(' (You)', '').trim().toLowerCase();
      if (uid != 'p1' && uid != 'user-default' && p.id == uid) {
        return p.rsvp;
      }
      if (widget.currentUserName != null && widget.currentUserName != 'Player' && normalizedName == widget.currentUserName!.trim().toLowerCase()) {
        return p.rsvp;
      }
      if ((uid == 'p1' || uid == 'user-default') && (p.id == 'p1' || p.name == 'You' || p.name.contains('(You)'))) {
        return p.rsvp;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return _buildEmptyState();
    }

    final s = widget.session!;
    final t = widget.duwaTheme;
    final isDark = t.isDark;
    final isVoting = s.status == GameNightStatus.voting;
    final gameTitle = s.selectedGame?.title ?? (isVoting ? 'Squad Game Vote' : s.title);
    final gameEmoji = s.selectedGame?.emoji ?? (isVoting ? '🗳️' : '🎮');
    final coverUrl = s.selectedGame?.optimizedCoverUrl(width: 800, height: 450);
    final current = _myRsvp;
    final locationName = s.location?.name;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: t.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 36 : 10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Meta Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timing / Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVoting ? t.secondaryContainer : t.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVoting ? Icons.how_to_vote_rounded : Icons.schedule_rounded,
                        size: 13,
                        color: isVoting ? t.secondaryAccent : t.primaryAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isVoting
                            ? 'Voting Open'
                            : (s.isTonight
                                ? 'Tonight · ${s.formattedTime}'
                                : '${s.formattedDate} · ${s.formattedTime}'),
                        style: TextStyle(
                          color: isVoting ? t.secondaryAccent : t.primaryAccent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Squad / Countdown indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    s.group.name,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Game & Session Info Area (Tappable for details)
          BouncyTap(
            onTap: widget.onOpenSession,
            scaleDown: 0.99,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Game Artwork / Emoji Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: t.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.cardBorder, width: 0.8),
                      ),
                      child: coverUrl != null && coverUrl.isNotEmpty
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(gameEmoji, style: const TextStyle(fontSize: 28)),
                              ),
                            )
                          : Center(
                              child: Text(gameEmoji, style: const TextStyle(fontSize: 28)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Session Title, Venue & Attendance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameTitle,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          locationName != null && locationName.isNotEmpty
                              ? '$locationName · ${s.group.name}'
                              : s.group.name,
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Attendees Row
                        Row(
                          children: [
                            AvatarGroup(
                              players: s.players,
                              maxVisible: 4,
                              radius: 10,
                              showStatusDot: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${s.goingCount} going',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (s.maybeCount > 0)
                              Text(
                                ' · ${s.maybeCount} maybe',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Subtle forward chevron
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: t.textMuted.withAlpha(150),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: t.cardBorder.withAlpha(140)),

          // 3. Bottom Interactive Action Row: 1-Tap RSVP or Vote
          if (isVoting)
            _buildVotingRow(s, t)
          else if (widget.onRsvpChanged != null)
            _buildRsvpRow(current, t),
        ],
      ),
    );
  }

  Widget _buildRsvpRow(RSVPStatus? current, DuwaThemeData t) {
    final options = [
      (RSVPStatus.going, "I'm In", DuwaColors.ionMint, Icons.check_circle_rounded),
      (RSVPStatus.maybe, "Maybe", DuwaColors.emberGold, Icons.help_outline_rounded),
      (RSVPStatus.cantGo, "Can't Go", const Color(0xFFEF4444), Icons.cancel_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: options.map((opt) {
          final rsvpStatus = opt.$1;
          final label = opt.$2;
          final statusColor = opt.$3;
          final icon = opt.$4;
          final isSelected = current == rsvpStatus;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BouncyTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _optimisticRsvp = rsvpStatus;
                  });
                  widget.onRsvpChanged?.call(rsvpStatus);
                },
                scaleDown: 0.95,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? statusColor.withAlpha(28) : t.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? statusColor : t.cardBorder.withAlpha(100),
                      width: isSelected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? statusColor : t.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? statusColor : t.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVotingRow(GameNightModel s, DuwaThemeData t) {
    return BouncyTap(
      onTap: widget.onOpenSession,
      scaleDown: 0.98,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote_rounded, size: 16, color: t.secondaryAccent),
            const SizedBox(width: 8),
            Text(
              s.votingGames.isNotEmpty
                  ? 'Vote for Game · ${s.votingGames.length} options open'
                  : 'Cast Your Vote Now',
              style: TextStyle(
                color: t.secondaryAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = widget.duwaTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.cardBorder, width: 1.0),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: t.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              color: t.primaryAccent,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ready to play?',
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No session planned tonight. Pick a game and rally the squad!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          BouncyTap(
            onTap: widget.onCreateSession,
            scaleDown: 0.95,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                gradient: t.primaryGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: DuwaTheme.cozyShadowLift,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Plan a Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
