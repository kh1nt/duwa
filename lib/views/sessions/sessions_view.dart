import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/game_pass_card.dart';
import '../common/state_feedback_views.dart';

enum SessionFilter { upcoming, needsYou, past }

/// Sessions: Chronological stream of squad game sessions.
class SessionsView extends StatefulWidget {
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;
  final ValueChanged<GameNightModel> onOpenSession;
  final VoidCallback onCreateSession;

  const SessionsView({
    super.key,
    required this.gameNightVm,
    required this.duwaTheme,
    required this.onOpenSession,
    required this.onCreateSession,
  });

  @override
  State<SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  SessionFilter _filter = SessionFilter.upcoming;
  int _selectedDayOffset = 0; // 0 = Today
  bool _isMonthView = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    return ListenableBuilder(
      listenable: widget.gameNightVm,
      builder: (_, __) {
        final allSessions = widget.gameNightVm.allSessions;
        final sessions = _visibleSessions(allSessions);
        final activeCount = widget.gameNightVm.upcomingSessions.length;
        final needsYouCount = allSessions
            .where((s) => s.status == GameNightStatus.voting || _myRsvp(s) == RSVPStatus.pending)
            .length;
        final archiveCount = widget.gameNightVm.recentGameNights.length;
        final currentUid = widget.gameNightVm.currentUserProfile?.id ?? 'p1';
        final currentUserName = widget.gameNightVm.currentUserProfile?.displayName;

        if (t.isCozy) {
          return Scaffold(
            backgroundColor: t.background,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(
                onPressed: widget.onCreateSession,
                backgroundColor: t.primaryAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.edit_calendar_rounded, size: 26),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
                children: [
                  // Sub-Header: Session Calendar / Schedule & View Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Calendar',
                            style: TextStyle(
                              color: t.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Schedule',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                      // View Switcher Pill
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.cardBorder, width: 0.8),
                          boxShadow: DuwaTheme.cozyShadow,
                        ),
                        child: Row(
                          children: [
                            BouncyTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isMonthView = false);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_isMonthView ? t.primaryAccent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.format_list_bulleted_rounded,
                                      size: 14,
                                      color: !_isMonthView ? Colors.white : t.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'List View',
                                      style: TextStyle(
                                        color: !_isMonthView ? Colors.white : t.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            BouncyTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isMonthView = true);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isMonthView ? t.primaryAccent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 14,
                                      color: _isMonthView ? Colors.white : t.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Month',
                                      style: TextStyle(
                                        color: _isMonthView ? Colors.white : t.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Calendar Ribbon
                  _buildCozyCalendarRibbon(t),
                  const SizedBox(height: 22),

                  // Timeline Section Header: Today
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: t.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today • ${_formatCurrentDay()}',
                            style: TextStyle(
                              color: t.primaryAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDCC5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${sessions.length} ${sessions.length == 1 ? "Session" : "Sessions"}',
                          style: const TextStyle(
                            color: Color(0xFF713700),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (sessions.isEmpty) ...[
                    _emptyState(t),
                    const SizedBox(height: 16),
                  ] else ...[
                    ...sessions.asMap().entries.map(
                      (entry) => _StaggeredSessionEntry(
                        key: ValueKey('cozy_${_selectedDayOffset}_${entry.value.id}'),
                        index: entry.key,
                        disableAnimations: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                        child: GamePassCard(
                          session: entry.value,
                          duwaTheme: t,
                          currentUserId: currentUid,
                          currentUserName: currentUserName,
                          isCompact: false,
                          onTap: () => widget.onOpenSession(entry.value),
                          onRsvpChanged: (RSVPStatus status) {
                            widget.gameNightVm.updatePlayerRSVP(entry.value.id, currentUid, status);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Open Slot Prompt Card (Stitch Spec)
                  _buildOpenSlotPromptCard(t),
                  const SizedBox(height: 22),

                  // Past archive link / count
                  if (archiveCount > 0) ...[
                    Row(
                      children: [
                        Text(
                          'COMPLETED SESSIONS',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('($archiveCount)', style: TextStyle(color: t.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.gameNightVm.recentGameNights.take(2).toList().asMap().entries.map(
                      (entry) => _StaggeredSessionEntry(
                        key: ValueKey('cozy_archive_${entry.value.id}'),
                        index: entry.key,
                        disableAnimations: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                        child: GamePassCard(
                          session: entry.value,
                          duwaTheme: t,
                          currentUserId: currentUid,
                          currentUserName: currentUserName,
                          isCompact: true,
                          onTap: () => widget.onOpenSession(entry.value),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            elevation: 0,
            title: Text(
              'Sessions',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              BouncyTap(
                onTap: widget.onCreateSession,
                scaleDown: 0.90,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: t.primaryAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Plan Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
            children: [
              _buildRadarHeader(t, activeCount, needsYouCount, archiveCount),
              const SizedBox(height: 20),

              // Filter segmented bar
              _filterBar(t, activeCount, needsYouCount, archiveCount),
              const SizedBox(height: 20),

              if (sessions.isEmpty)
                _emptyState(t)
              else
                ...sessions.asMap().entries.map(
                  (entry) => _StaggeredSessionEntry(
                    key: ValueKey('${_filter.name}_${entry.value.id}'),
                    index: entry.key,
                    disableAnimations: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                    child: GamePassCard(
                      session: entry.value,
                      duwaTheme: t,
                      currentUserId: currentUid,
                      currentUserName: currentUserName,
                      isCompact: false,
                      onTap: () => widget.onOpenSession(entry.value),
                      onRsvpChanged: (RSVPStatus status) {
                        widget.gameNightVm.updatePlayerRSVP(entry.value.id, currentUid, status);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<GameNightModel> _visibleSessions(List<GameNightModel> all) {
    switch (_filter) {
      case SessionFilter.upcoming:
        return widget.gameNightVm.upcomingSessions;
      case SessionFilter.needsYou:
        return all
            .where((s) => s.status == GameNightStatus.voting || _myRsvp(s) == RSVPStatus.pending)
            .toList();
      case SessionFilter.past:
        return widget.gameNightVm.recentGameNights;
    }
  }

  RSVPStatus? _myRsvp(GameNightModel s) {
    final userId = widget.gameNightVm.currentUserProfile?.id;
    for (final player in s.players) {
      if (player.id == userId || player.id == 'p1' || player.name == 'You' || player.name.contains('(You)')) {
        return player.rsvp;
      }
    }
    return null;
  }

  Widget _buildRadarHeader(DuwaThemeData t, int activeCount, int needsYouCount, int archiveCount) {
    final hasAttention = needsYouCount > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.cardBorder),
        boxShadow: [
          BoxShadow(
            color: t.primaryAccent.withAlpha(t.isCleanLight ? 14 : 24),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSION RADAR',
                      style: TextStyle(
                        color: t.primaryAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasAttention ? 'A few things need you.' : 'Everything is on track.',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasAttention
                          ? 'Vote or confirm your spot so your squad can keep moving.'
                          : 'Your upcoming plans will appear here.',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.primaryAccent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    hasAttention ? Icons.priority_high_rounded : Icons.check_rounded,
                    key: ValueKey(hasAttention),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              _radarMetric(t, activeCount, 'active'),
              _radarDivider(t),
              _radarMetric(t, needsYouCount, 'needs you'),
              _radarDivider(t),
              _radarMetric(t, archiveCount, 'completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _radarMetric(DuwaThemeData t, int value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Text(label, style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _radarDivider(DuwaThemeData t) => Container(
        width: 1,
        height: 27,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: t.cardBorder,
      );

  Widget _filterBar(DuwaThemeData t, int activeCount, int needsYouCount, int archiveCount) {
    final filters = [
      ('ACTIVE', activeCount, SessionFilter.upcoming),
      ('NEEDS YOU', needsYouCount, SessionFilter.needsYou),
      ('ARCHIVE', archiveCount, SessionFilter.past),
    ];
    final selectedIndex = filters.indexWhere((f) => f.$3 == _filter).clamp(0, 2);
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          final tabHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Smooth Sliding Active Pill Indicator
              AnimatedPositioned(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                top: 0,
                width: tabWidth,
                height: tabHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.surfaceHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder.withAlpha(90), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab Items
              Row(
                children: filters.map((f) {
                  final isSelected = _filter == f.$3;
                  return Expanded(
                    child: BouncyTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f.$3);
                      },
                      scaleDown: 0.96,
                      child: Container(
                        height: double.infinity,
                        alignment: Alignment.center,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                color: isSelected ? t.textPrimary : t.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                              child: Text(f.$1),
                            ),
                            const SizedBox(width: 5),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                color: isSelected ? t.primaryAccent : t.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                              child: Text('${f.$2}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(DuwaThemeData t) => EmptyStateWidget.sessions(
        onCreate: widget.onCreateSession,
      );

  String _formatCurrentDay() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildCozyCalendarRibbon(DuwaThemeData t) {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // -1 to +5 days relative to today
          final offset = index - 1;
          final dayDate = now.add(Duration(days: offset));
          final isSelected = _selectedDayOffset == offset;
          final weekdayStr = weekdays[dayDate.weekday - 1];

          return BouncyTap(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDayOffset = offset);
            },
            scaleDown: 0.94,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? t.primaryAccent : t.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? t.primaryAccent : t.cardBorder,
                  width: 1.0,
                ),
                boxShadow: isSelected ? DuwaTheme.cozyShadowLift : DuwaTheme.cozyShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      color: isSelected ? Colors.white.withAlpha(220) : t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDCC5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpenSlotPromptCard(DuwaThemeData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bedtime_rounded, color: t.primaryAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Got free time tonight?',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open slot after 8:30 PM',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          BouncyTap(
            onTap: widget.onCreateSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: t.primaryAccent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: DuwaTheme.cozyShadow,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.add_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile staggered entrance animation for session cards.
/// Provides a subtle upward slide and fade with deceleration easing.
class _StaggeredSessionEntry extends StatelessWidget {
  final Widget child;
  final int index;
  final bool disableAnimations;

  const _StaggeredSessionEntry({
    super.key,
    required this.child,
    required this.index,
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    if (disableAnimations) return child;
    final delay = (index * 40).clamp(0, 200);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1.0 - value)),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}

