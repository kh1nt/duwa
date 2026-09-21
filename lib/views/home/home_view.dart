import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import '../../models/user_profile_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/game_pass_card.dart';
import '../common/hero_session_marquee.dart';
import '../common/join_code_dialog.dart';
import '../common/add_game_sheet.dart';
import '../common/random_game_sheet.dart';
import '../notifications/notifications_view.dart';
import 'home_bento_hub.dart';
import '../common/duwa_logo.dart';

/// The home dashboard: a quick read on the squad, the next session, and the
/// fastest ways to get everyone playing.
class HomeView extends StatelessWidget {
  final GameNightViewModel gameNightVm;
  final GroupsViewModel groupsVm;
  final ThemeViewModel themeVm;
  final ProfileViewModel? profileVm;
  final NotificationsViewModel? notificationsVm;
  final int unreadNotificationsCount;
  final VoidCallback onOpenSessions;
  final VoidCallback onCreateGameNight;
  final void Function(GameModel? initialGame)? onPlanWithGame;
  final Function(GameNightModel) onOpenGameNight;
  final Function(GamerGroupModel) onOpenGroup;

  const HomeView({
    super.key,
    required this.gameNightVm,
    required this.groupsVm,
    required this.themeVm,
    this.profileVm,
    this.notificationsVm,
    required this.unreadNotificationsCount,
    required this.onOpenSessions,
    required this.onCreateGameNight,
    this.onPlanWithGame,
    required this.onOpenGameNight,
    required this.onOpenGroup,
  });

  RSVPStatus? _myRsvpForSession(GameNightModel s, String uid, String? userName) {
    for (final p in s.players) {
      final normalizedName = p.name.replaceAll(' (You)', '').trim().toLowerCase();
      if (uid != 'p1' && uid != 'user-default' && p.id == uid) {
        return p.rsvp;
      }
      if (userName != null && userName != 'Player' && normalizedName == userName.trim().toLowerCase()) {
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
    final listenables = <Listenable>[
      gameNightVm,
      groupsVm,
      themeVm,
      if (profileVm != null) profileVm!,
      if (notificationsVm != null) notificationsVm!,
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final t = themeVm.themeData;

        final upcomingSessions = gameNightVm.upcomingSessions;
        final currentUid = gameNightVm.currentUserProfile?.id ?? 'p1';
        final currentUserName = gameNightVm.currentUserProfile?.displayName;

        // Detect user's dynamic priority context
        GameNightModel? pendingInviteSession;
        GameNightModel? activeVotingSession;
        GameNightModel? incompletePrepSession;

        for (final s in upcomingSessions) {
          final rsvp = _myRsvpForSession(s, currentUid, currentUserName);
          if (pendingInviteSession == null && rsvp == RSVPStatus.pending) {
            pendingInviteSession = s;
          }
          if (activeVotingSession == null && s.status == GameNightStatus.voting) {
            activeVotingSession = s;
          }
          final hasUnassigned = s.checklist.any((i) => i.assignedTo == null || i.assignedTo!.isEmpty);
          final needsFood = s.food == null || s.food!.title.isEmpty;
          if (incompletePrepSession == null && (hasUnassigned || needsFood) && s.status != GameNightStatus.voting) {
            incompletePrepSession = s;
          }
        }

        final nextSession = upcomingSessions.isNotEmpty ? upcomingSessions.first : null;
        final otherUpcoming = upcomingSessions.length > 1
            ? upcomingSessions.sublist(1, upcomingSessions.length.clamp(1, 4))
            : <GameNightModel>[];

        final recentSessions = gameNightVm.recentGameNights.take(2).toList();

        return Scaffold(
          backgroundColor: t.background,
          appBar: _buildAppBar(context, t),
          body: RefreshIndicator(
            color: t.primaryAccent,
            backgroundColor: t.surface,
            onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 350)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
              children: [
                _buildBriefingHeader(t, profileVm?.profile),
                const SizedBox(height: 18),

                // 1. Dynamic Priority Section: Pending Invitation, Active Voting, Incomplete Prep (only if not hero)
                if (pendingInviteSession != null && pendingInviteSession.id != nextSession?.id) ...[
                  _buildInvitationBanner(context, t, pendingInviteSession, currentUid),
                  const SizedBox(height: 16),
                ] else if (activeVotingSession != null && activeVotingSession.id != nextSession?.id) ...[
                  _buildVotingActionBanner(context, t, activeVotingSession),
                  const SizedBox(height: 16),
                ] else if (incompletePrepSession != null && incompletePrepSession.id != nextSession?.id) ...[
                  _buildPrepActionBanner(context, t, incompletePrepSession),
                  const SizedBox(height: 16),
                ],

                // 2. Primary Hero Session (or Empty State)
                _buildSectionHeader('Next Session', t),
                const SizedBox(height: 10),
                HeroSessionMarquee(
                  session: nextSession,
                  duwaTheme: t,
                  currentUserId: currentUid,
                  currentUserName: currentUserName,
                  onOpenSession: () {
                    if (nextSession != null) onOpenGameNight(nextSession);
                  },
                  onCreateSession: onCreateGameNight,
                  onRsvpChanged: nextSession != null
                      ? (RSVPStatus newRsvp) {
                          gameNightVm.updatePlayerRSVP(nextSession.id, currentUid, newRsvp);
                        }
                      : null,
                ),
                const SizedBox(height: 20),

                // 3. Action Command Hub
                _buildQuickActionStrip(context, t, activeVotingSession: activeVotingSession),
                const SizedBox(height: 24),

                // 4. Other Upcoming Game Nights / Sessions
                if (otherUpcoming.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Upcoming Sessions', t, count: otherUpcoming.length),
                      InkWell(
                        onTap: onOpenSessions,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'See all',
                            style: TextStyle(
                              color: t.primaryAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...otherUpcoming.map(
                    (s) => GamePassCard(
                      session: s,
                      duwaTheme: t,
                      currentUserId: currentUid,
                      currentUserName: currentUserName,
                      isCompact: true,
                      onTap: () => onOpenGameNight(s),
                      onRsvpChanged: (RSVPStatus status) {
                        gameNightVm.updatePlayerRSVP(s.id, currentUid, status);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Recent Sessions / History
                if (recentSessions.isNotEmpty) ...[
                  _buildSectionHeader('Recent Sessions', t, count: recentSessions.length),
                  const SizedBox(height: 12),
                  ...recentSessions.map((s) => _buildArchiveTile(s, t)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DuwaThemeData t) {
    return AppBar(
      titleSpacing: 18,
      backgroundColor: t.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: DuwaLogo(
              size: DuwaLogoSize.small,
              showWordmark: false,
              withGlow: false,
              customSize: 36,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DUWA',
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Squad Coordination',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Alerts & Activity',
              icon: Icon(Icons.notifications_outlined, color: t.textPrimary, size: 22),
              onPressed: () {
                if (notificationsVm != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsView(
                        notificationsVm: notificationsVm!,
                        duwaTheme: t,
                      ),
                    ),
                  );
                }
              },
            ),
            if (unreadNotificationsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DuwaColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadNotificationsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildBriefingHeader(DuwaThemeData t, UserProfileModel? profile) {
    final name = profile?.displayName.isNotEmpty == true ? profile!.displayName : 'Player';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hey, $name 👋',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Ready for game night?',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: DuwaColors.presenceOnline.withAlpha(22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DuwaColors.presenceOnline.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: DuwaColors.presenceOnline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Squad Active',
                style: TextStyle(
                  color: DuwaColors.presenceOnline,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationBanner(
    BuildContext context,
    DuwaThemeData t,
    GameNightModel s,
    String currentUid,
  ) {
    final gameTitle = s.selectedGame?.title ?? (s.status == GameNightStatus.voting ? 'Squad Game Vote' : s.title);
    final foodText = s.food?.title ?? 'Snacks & food';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(t.isDark ? 35 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t.primaryAccent.withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mark_email_unread_rounded, size: 13, color: t.primaryAccent),
                    const SizedBox(width: 5),
                    Text(
                      "YOU'RE INVITED",
                      style: TextStyle(
                        color: t.primaryAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Host: ${s.organizerDisplay}',
                style: TextStyle(color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.title,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _infoPill(Icons.sports_esports_rounded, gameTitle, t),
              _infoPill(Icons.calendar_today_rounded, '${s.formattedDate} · ${s.formattedTime}', t),
              _infoPill(Icons.people_rounded, '${s.goingCount} going', t),
              _infoPill(Icons.restaurant_rounded, foodText, t),
            ],
          ),
          const SizedBox(height: 14),
          // 1-Tap RSVP Options
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    gameNightVm.updatePlayerRSVP(s.id, currentUid, RSVPStatus.going);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("You're in for ${s.title}! 🎮")),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "I'm Going",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncyTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    gameNightVm.updatePlayerRSVP(s.id, currentUid, RSVPStatus.maybe);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Text(
                      'Maybe',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncyTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    gameNightVm.updatePlayerRSVP(s.id, currentUid, RSVPStatus.cantGo);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Text(
                      "Can't Go",
                      style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w700, fontSize: 12),
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

  Widget _buildVotingActionBanner(
    BuildContext context,
    DuwaThemeData t,
    GameNightModel s,
  ) {
    return BouncyTap(
      onTap: () => onOpenGameNight(s),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(t.isDark ? 30 : 8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: t.cardBorder, width: 0.8),
              ),
              child: Icon(Icons.how_to_vote_rounded, color: t.primaryAccent, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help choose the game',
                    style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.title} · ${s.votingGames.length} options nominated',
                    style: TextStyle(color: t.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: t.primaryAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Vote Now',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepActionBanner(
    BuildContext context,
    DuwaThemeData t,
    GameNightModel s,
  ) {
    return BouncyTap(
      onTap: () => onOpenGameNight(s),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(t.isDark ? 30 : 8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: t.cardBorder, width: 0.8),
              ),
              child: Icon(Icons.checklist_rounded, color: t.textPrimary, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Night needs you',
                    style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.title} · Claim items or check food plan',
                    style: TextStyle(color: t.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.cardBorder),
              ),
              child: Text(
                'View Prep',
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, DuwaThemeData t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: t.primaryAccent),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _openJoinDialog(BuildContext context, DuwaThemeData t) {
    JoinCodeDialog.show(
      context,
      duwaTheme: t,
      onJoined: (data) async {
        if (data['type'] == 'squad') {
          final squadName = data['name'] ?? 'Squad';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined squad $squadName! 👥')),
          );
          return;
        }
        final title = data['title'] ?? 'Session';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $title! 🎮')),
        );
        final id = data['id'] as String?;
        if (id != null) {
          final matched = gameNightVm.allSessions.where((s) => s.id == id).firstOrNull;
          if (matched != null) {
            onOpenGameNight(matched);
          } else {
            final code = data['roomCode'] as String? ?? id;
            final loaded = await gameNightVm.joinSessionByCode(code);
            if (loaded != null) {
              onOpenGameNight(loaded);
            }
          }
        }
      },
    );
  }

  Widget _buildQuickActionStrip(
    BuildContext context,
    DuwaThemeData t, {
    GameNightModel? activeVotingSession,
  }) {
    return HomeBentoHub(
      duwaTheme: t,
      onPlanSession: onCreateGameNight,
      onJoinCode: () => _openJoinDialog(context, t),
      onRandomGame: () {
        RandomGameSheet.show(
          context,
          games: gameNightVm.catalogGames,
          duwaTheme: t,
          onAddGame: () {
            Navigator.pop(context);
            AddGameSheet.show(
              context,
              gameNightVm: gameNightVm,
              duwaTheme: t,
            );
          },
          onPlanGame: (game) {
            if (onPlanWithGame != null) {
              onPlanWithGame!(game);
            } else {
              onCreateGameNight();
            }
          },
        );
      },
      onQuickVote: () {
        if (activeVotingSession != null) {
          onOpenGameNight(activeVotingSession);
        } else {
          onCreateGameNight();
        }
      },
    );
  }

  Widget _buildSectionHeader(String title, DuwaThemeData t, {int? count}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: t.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArchiveTile(GameNightModel s, DuwaThemeData t) {
    return BouncyTap(
      onTap: () => onOpenGameNight(s),
      scaleDown: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.selectedGame?.emoji ?? '🎮',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.formattedDate} · ${s.historyHighlight ?? "Session Completed"}',
                    style: TextStyle(color: t.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'COMPLETED',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

