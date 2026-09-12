import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/preparation_widgets.dart';
import 'game_night_dispatch_sheet.dart';

class GameNightDetailsView extends StatefulWidget {
  final GameNightModel gameNight;
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;

  const GameNightDetailsView({
    super.key,
    required this.gameNight,
    required this.gameNightVm,
    required this.duwaTheme,
  });

  @override
  State<GameNightDetailsView> createState() => _GameNightDetailsViewState();
}

class _GameNightDetailsViewState extends State<GameNightDetailsView> {

  GameNightModel _activeSession() {
    return widget.gameNightVm.getSessionById(widget.gameNight.id);
  }

  RSVPStatus? _myRsvp(GameNightModel s) {
    final myId = widget.gameNightVm.currentUserProfile?.id;
    for (final p in s.players) {
      if (p.id == myId || p.id == 'p1' || p.name == 'You' || p.name.contains('(You)')) {
        return p.rsvp;
      }
    }
    return null;
  }

  bool _isHost(GameNightModel s) {
    return s.isHost ||
        s.organizerName == 'You' ||
        (widget.gameNightVm.currentUserProfile != null &&
            s.organizerName == widget.gameNightVm.currentUserProfile!.displayName);
  }

  void _openDispatchSheet(GameNightModel session, DuwaThemeData theme) {
    GameNightDispatchSheet.show(
      context,
      gameNight: session,
      duwaTheme: theme,
    );
  }

  void _copyInviteCode(GameNightModel session) {
    Clipboard.setData(ClipboardData(text: session.displayRoomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code ${session.displayRoomCode} copied! 🎮')),
    );
  }

  void _confirmDeleteSession(BuildContext context, GameNightModel session) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: widget.duwaTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Session?',
          style: TextStyle(color: widget.duwaTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${session.title}"? This action cannot be undone.',
          style: TextStyle(color: widget.duwaTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Cancel', style: TextStyle(color: widget.duwaTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              widget.gameNightVm.deleteSession(session.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session "${session.title}" deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value, GameNightModel session, DuwaThemeData t) {
    if (value == 'dispatch') {
      _openDispatchSheet(session, t);
    } else if (value == 'copy') {
      _copyInviteCode(session);
    } else if (value == 'lock') {
      widget.gameNightVm.lockVoting(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voting locked! Switched to Planning.')),
      );
    } else if (value == 'ready') {
      widget.gameNightVm.markSessionReady(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session marked as Ready!')),
      );
    } else if (value == 'complete') {
      widget.gameNightVm.markSessionCompleted(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session marked as Completed! 🏆')),
      );
    } else if (value == 'cancel') {
      widget.gameNightVm.cancelSession(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session cancelled.')),
      );
    } else if (value == 'delete') {
      _confirmDeleteSession(context, session);
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(GameNightModel session, DuwaThemeData t) {
    return [
      const PopupMenuItem(
        value: 'dispatch',
        child: Row(
          children: [
            Icon(Icons.send_rounded, size: 18),
            SizedBox(width: 8),
            Text('Share Dispatch'),
          ],
        ),
      ),
      if (session.status != GameNightStatus.completed && session.status != GameNightStatus.cancelled)
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18),
              SizedBox(width: 8),
              Text('Copy invite code'),
            ],
          ),
        ),
      if (_isHost(session) && session.status == GameNightStatus.voting)
        const PopupMenuItem(
          value: 'lock',
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18),
              SizedBox(width: 8),
              Text('Lock voting & plan'),
            ],
          ),
        ),
      if (_isHost(session) && session.status == GameNightStatus.planning)
        const PopupMenuItem(
          value: 'ready',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 18),
              SizedBox(width: 8),
              Text('Mark session ready'),
            ],
          ),
        ),
      if (_isHost(session) && session.status == GameNightStatus.ready)
        const PopupMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 18, color: DuwaColors.ionMint),
              SizedBox(width: 8),
              Text('Mark completed 🏆', style: TextStyle(color: DuwaColors.ionMint)),
            ],
          ),
        ),
      if (_isHost(session) && session.status != GameNightStatus.cancelled && session.status != GameNightStatus.completed)
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Cancel session', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete session', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameNightVm,
      builder: (context, _) {
        final session = _activeSession();
        final t = widget.duwaTheme;

        return Scaffold(
          backgroundColor: t.background,
          appBar: _buildCozyAppBar(session, t),
          body: _buildCozyBody(session, t),
          bottomNavigationBar: _buildCozyBottomActionBar(session, t),
        );
      },
    );
  }

  // ===================== COZY WELLNESS DESIGN SYSTEM (STITCH SCREEN 3) =====================

  PreferredSizeWidget _buildCozyAppBar(GameNightModel s, DuwaThemeData t) {
    return AppBar(
      backgroundColor: t.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Center(
          child: BouncyTap(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: t.cardBorder, width: 1.2),
                boxShadow: DuwaTheme.cozyShadow,
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: t.textPrimary),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Session Details',
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: DuwaColors.cozySuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Room #${s.displayRoomCode}',
                style: TextStyle(
                  color: t.secondaryAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Center(
            child: PopupMenuButton<String>(
              icon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.cardBorder, width: 1.2),
                  boxShadow: DuwaTheme.cozyShadow,
                ),
                child: Icon(Icons.more_horiz_rounded, size: 20, color: t.textPrimary),
              ),
              color: t.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onSelected: (val) => _handleMenuSelection(val, s, t),
              itemBuilder: (ctx) => _buildMenuItems(s, t),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCozyBody(GameNightModel s, DuwaThemeData t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
      children: [
        // 1. Hero Game Banner Card
        _buildCozyHeroBanner(s, t),
        const SizedBox(height: 14),

        // 2. Voting Card (if active)
        if (s.status == GameNightStatus.voting) ...[
          _buildCozyVotingCard(s, t),
          const SizedBox(height: 14),
        ],

        // 3. Bento Schedule Grid
        _buildCozyScheduleGrid(s, t),
        const SizedBox(height: 14),

        // 4. Squad & Participants Section
        _buildCozySquadCard(s, t),
        const SizedBox(height: 14),

        // 5. Host Note / Cozy Ritual Card
        _buildCozyHostNoteCard(s, t),
        const SizedBox(height: 14),

        // 6. Preparation checklist if items exist
        if (s.checklist.isNotEmpty) ...[
          _buildCozyChecklistCard(s, t),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildCozyHeroBanner(GameNightModel s, DuwaThemeData t) {
    final isVoting = s.status == GameNightStatus.voting;
    final displayTitle = s.selectedGame?.title ?? (isVoting ? 'Squad Vote in Progress' : s.title);
    final coverUrl = s.selectedGame?.displayCoverUrl;
    final totalSlots = s.maxPlayers;
    final squadCount = s.goingCount;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Backdrop (height 192, 22px radius)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 192,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackGraphic(s, t),
                    )
                  else
                    _buildFallbackGraphic(s, t),

                  // Gradient scrim
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(80),
                          Colors.black.withAlpha(210),
                        ],
                        stops: const [0.35, 0.65, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Top right floating status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: t.surface.withAlpha(235),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.cardBorder, width: 1),
                        boxShadow: DuwaTheme.cozyShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: s.status == GameNightStatus.ready
                                  ? DuwaColors.cozySuccess
                                  : DuwaColors.cozyTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.status == GameNightStatus.ready ? 'Live Lobby' : 'Scheduled',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // In-banner bottom tags + Title
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: t.primaryAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.selectedGame?.genre ?? 'Competitive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: t.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$squadCount / $totalSlots Squad',
                                style: TextStyle(
                                  color: t.primaryAccent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Meta strip underneath cover art
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Host Organizer badge
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: t.secondaryContainer,
                          child: Text(
                            (s.organizerName != null && s.organizerName!.isNotEmpty)
                                ? s.organizerName![0].toUpperCase()
                                : 'H',
                            style: TextStyle(
                              color: t.primaryAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: t.primaryAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.surface, width: 1.5),
                            ),
                            child: const Icon(Icons.star_rounded, size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Host Organizer',
                          style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          s.organizerDisplay,
                          style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),

                // Countdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.tertiaryAccent.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: t.tertiaryAccent),
                      const SizedBox(width: 5),
                      Text(
                        'Starts ${s.formattedTime}',
                        style: TextStyle(
                          color: t.onTertiaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackGraphic(GameNightModel s, DuwaThemeData t) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.primaryAccent,
            t.secondaryAccent,
            t.tertiaryAccent.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          s.selectedGame?.emoji ?? '🎮',
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildCozyScheduleGrid(GameNightModel s, DuwaThemeData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 18, color: t.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'Session Schedule',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  title: s.isTonight ? 'Tonight' : s.weekdayShort,
                  subtitle: s.formattedDate,
                  t: t,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBentoTile(
                  icon: Icons.schedule_rounded,
                  label: 'Time Slot',
                  title: s.formattedTime,
                  subtitle: '2 Hours duration',
                  t: t,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  icon: Icons.sports_esports_rounded,
                  label: 'Platform',
                  title: s.selectedGame?.platform ?? 'PC Gaming',
                  subtitle: 'Crossplay Ready',
                  t: t,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBentoTile(
                  icon: Icons.mic_rounded,
                  label: 'Voice Lounge',
                  title: 'Discord Audio',
                  subtitle: '#${s.location?.name ?? 'chill-queue'}',
                  t: t,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoTile({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required DuwaThemeData t,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: t.primaryAccent),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.secondaryAccent,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCozySquadCard(GameNightModel s, DuwaThemeData t) {
    final totalSlots = s.maxPlayers;
    final openSlots = (totalSlots - s.goingCount).clamp(0, totalSlots);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Squad Participants',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: t.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${s.goingCount} / $totalSlots',
                  style: TextStyle(
                    color: t.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                openSlots > 0 ? '$openSlots Slot${openSlots == 1 ? '' : 's'} Open' : 'Squad Full',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Participants list
          Column(
            children: s.players.map((p) {
              final isPlayerHost = p.isHost || p.name == s.organizerName;
              final isGoing = p.rsvp == RSVPStatus.going;
              final isMaybe = p.rsvp == RSVPStatus.maybe;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: isGoing ? t.secondaryContainer : t.surfaceHighest,
                      child: Text(
                        p.avatarEmoji ?? p.avatarInitials,
                        style: TextStyle(
                          color: t.primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isPlayerHost) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: t.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Host',
                                    style: TextStyle(
                                      color: t.onTertiaryContainer,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.preferredRole,
                            style: TextStyle(color: t.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGoing
                            ? DuwaColors.cozySuccess.withAlpha(25)
                            : (isMaybe ? DuwaColors.cozyTertiary.withAlpha(25) : t.surfaceHighest),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isGoing
                                  ? DuwaColors.cozySuccess
                                  : (isMaybe ? DuwaColors.cozyTertiary : t.textMuted),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isGoing ? 'Ready' : (isMaybe ? 'Joined' : 'Pending'),
                            style: TextStyle(
                              color: isGoing
                                  ? DuwaColors.cozySuccess
                                  : (isMaybe ? DuwaColors.cozyTertiary : t.textMuted),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Action Buttons Row: Invite Friends + Chat / Voice
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  onTap: () => _copyInviteCode(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: t.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 16, color: t.primaryAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Invite Friends',
                          style: TextStyle(
                            color: t.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BouncyTap(
                  onTap: () => _openDispatchSheet(s, t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surfaceHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: t.textPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Chat / Voice',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCozyHostNoteCard(GameNightModel s, DuwaThemeData t) {
    final noteText = s.description.isNotEmpty
        ? s.description
        : 'Ranked grind to Plat! Bring snacks and good vibes only ☕. Remember water breaks between matches!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.coffee_rounded, size: 20, color: t.tertiaryAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Host Note',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  noteText,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCozyVotingCard(GameNightModel s, DuwaThemeData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote_rounded, size: 18, color: t.secondaryAccent),
              const SizedBox(width: 8),
              Text(
                'Vote for the Game',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (_isHost(s))
                GestureDetector(
                  onTap: () => widget.gameNightVm.lockVoting(s.id),
                  child: Text(
                    'Lock voting',
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...s.votingGames.map((g) => _voteOptionTile(s, g, t)),
        ],
      ),
    );
  }

  Widget _voteOptionTile(GameNightModel s, GameModel g, DuwaThemeData t) {
    final isMyVote = s.userVotedGameId == g.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyVote ? t.primaryAccent.withAlpha(30) : t.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyVote ? t.primaryAccent : t.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(g.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.title,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${g.votes} votes',
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          BouncyTap(
            onTap: () => widget.gameNightVm.castVote(s.id, g.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMyVote ? t.primaryAccent : t.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isMyVote ? 'Voted' : 'Vote',
                style: TextStyle(
                  color: isMyVote ? Colors.white : t.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCozyChecklistCard(GameNightModel s, DuwaThemeData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: t.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'Preparation & Essentials',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PreparationSummaryWidget(
            gameNight: s,
            duwaTheme: t,
            onToggleChecklist: (id) => widget.gameNightVm.toggleChecklistItem(s.id, id),
            onClaimItem: (id) => widget.gameNightVm.claimChecklistItem(s.id, id),
          ),
        ],
      ),
    );
  }

  Widget _buildCozyBottomActionBar(GameNightModel s, DuwaThemeData t) {
    final myRsvp = _myRsvp(s);
    final isGoing = myRsvp == RSVPStatus.going;

    return Container(
      decoration: BoxDecoration(
        color: t.surface.withAlpha(245),
        border: Border(top: BorderSide(color: t.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Row(
        children: [
          // Edit Details Button
          Expanded(
            flex: 1,
            child: BouncyTap(
              onTap: () => _openDispatchSheet(s, t),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: t.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune_rounded, size: 17, color: t.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Edit Details',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ready Up / I'm In CTA
          Expanded(
            flex: 2,
            child: BouncyTap(
              onTap: () {
                HapticFeedback.heavyImpact();
                final myId = widget.gameNightVm.currentUserProfile?.id ?? 'p1';
                final newStatus = isGoing ? RSVPStatus.maybe : RSVPStatus.going;
                widget.gameNightVm.updatePlayerRSVP(s.id, myId, newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newStatus == RSVPStatus.going ? "Ready Up confirmed! You're in 🎮" : 'RSVP updated.',
                    ),
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isGoing ? DuwaColors.cozySuccess : t.primaryAccent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: DuwaTheme.cozyShadowLift,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isGoing ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isGoing ? "Ready & In Squad" : "Ready Up",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
