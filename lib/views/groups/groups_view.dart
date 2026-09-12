import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_night_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../common/duwa_buttons.dart';
import '../common/bouncy_tap.dart';

/// Manage recurring friend groups, squad members, and squad-specific sessions.
class GroupsView extends StatelessWidget {
  final GroupsViewModel groupsVm;
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;
  final ValueChanged<GamerGroupModel> onPlanGameNightForGroup;
  final ValueChanged<GameModel> onPlanGameNightForGame;

  const GroupsView({
    super.key,
    required this.groupsVm,
    required this.gameNightVm,
    required this.duwaTheme,
    required this.onPlanGameNightForGroup,
    required this.onPlanGameNightForGame,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([groupsVm, gameNightVm]),
      builder: (context, _) {
        final groups = groupsVm.groups;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Squads'),
            actions: [
              IconButton(
                tooltip: 'Join with code',
                onPressed: () => _joinWithCode(context),
                icon: const Icon(Icons.vpn_key_outlined),
              ),
              IconButton(
                tooltip: 'Create squad',
                onPressed: () => _createSquad(context),
                icon: Icon(Icons.add_rounded, color: duwaTheme.primaryAccent),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: [
              _header(),
              const SizedBox(height: 16),
              _buildSquadOverview(groups),
              const SizedBox(height: 24),
              if (groups.isEmpty)
                _emptyState(context)
              else
                ...groups.map((g) => _squadCard(context, g)),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your gaming squads',
          style: TextStyle(
            color: duwaTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Manage friend groups, plan sessions, and keep track of your regular crews.',
          style: TextStyle(
            color: duwaTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSquadOverview(List<GamerGroupModel> groups) {
    final memberCount = groups.fold<int>(0, (total, group) => total + group.memberCount);
    final plannedCount = gameNightVm.upcomingSessions
        .where((session) => groups.any((group) => group.id == session.group.id))
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: duwaTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: duwaTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(duwaTheme.isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: duwaTheme.primaryAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groups.isEmpty ? 'Your people are one tap away.' : 'Your people, in one place.',
                  style: TextStyle(
                    color: duwaTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$memberCount members across ${groups.length} ${groups.length == 1 ? 'squad' : 'squads'}',
                  style: TextStyle(color: duwaTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$plannedCount',
                style: TextStyle(
                  color: duwaTheme.primaryAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'planned',
                style: TextStyle(color: duwaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  GameNightModel? _findNextSession(String groupId) {
    for (final s in gameNightVm.allSessions) {
      if (s.group.id == groupId &&
          s.status != GameNightStatus.completed &&
          s.status != GameNightStatus.cancelled) {
        return s;
      }
    }
    return null;
  }

  Widget _squadCard(BuildContext context, GamerGroupModel g) {
    final nextSession = _findNextSession(g.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSquadDetail(context, g),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: duwaTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: duwaTheme.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: duwaTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(g.iconEmoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.name,
                            style: TextStyle(
                              color: duwaTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: duwaTheme.surfaceHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${g.memberCount} members',
                            style: TextStyle(
                              color: duwaTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      g.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: duwaTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (nextSession != null)
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 13, color: duwaTheme.primaryAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Next: ${nextSession.title} · ${nextSession.formattedDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: duwaTheme.primaryAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Last played ${g.recentGame}',
                        style: TextStyle(
                          color: duwaTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: duwaTheme.textMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  if (value == 'details') {
                    _showSquadDetail(context, g);
                  } else if (value == 'invite') {
                    _showInviteSquadSheet(context, g);
                  } else if (value == 'plan') {
                    onPlanGameNightForGroup(g);
                  } else if (value == 'delete') {
                    _confirmDeleteSquad(context, null, g);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Squad Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'invite',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Invite to Squad'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'plan',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Plan Session'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Squad', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: duwaTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: duwaTheme.cardBorder),
      ),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 12),
          Text(
            'Create your first squad',
            style: TextStyle(
              color: duwaTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bring your gaming friends together so planning sessions takes seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: duwaTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DuwaButton(
                label: 'Create squad',
                icon: Icons.add_rounded,
                onPressed: () => _createSquad(context),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _joinWithCode(context),
                child: const Text('Join with code'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSquadDetail(BuildContext context, GamerGroupModel initialGroup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: duwaTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => ListenableBuilder(
        listenable: groupsVm,
        builder: (context, _) {
          final g = groupsVm.groups.firstWhere((x) => x.id == initialGroup.id, orElse: () => initialGroup);
          final squadUpcoming = gameNightVm.allSessions
              .where((s) =>
                  s.group.id == g.id &&
                  s.status != GameNightStatus.completed &&
                  s.status != GameNightStatus.cancelled)
              .toList();
          final squadPast = gameNightVm.allSessions
              .where((s) => s.group.id == g.id && s.status == GameNightStatus.completed)
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: duwaTheme.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: duwaTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(g.iconEmoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: TextStyle(
                                color: duwaTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              g.tagline,
                              style: TextStyle(
                                color: duwaTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Squad invite link / code
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: duwaTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: duwaTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18, color: duwaTheme.primaryAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Invite code: SQ-${g.id.toUpperCase().replaceAll('-', '')}',
                            style: TextStyle(
                              color: duwaTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: 'SQ-${g.id.toUpperCase().replaceAll('-', '')}'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Squad invite code copied!')),
                            );
                          },
                          child: Text(
                            'Copy',
                            style: TextStyle(
                              color: duwaTheme.primaryAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MEMBERS (${g.memberCount})',
                        style: TextStyle(
                          color: duwaTheme.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showInviteSquadSheet(context, g),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 14, color: duwaTheme.primaryAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Invite / Add',
                                style: TextStyle(
                                  color: duwaTheme.primaryAccent,
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: g.members.map((p) {
                      return Chip(
                        label: Text(p.name.replaceAll(' (You)', '')),
                        avatar: CircleAvatar(
                          backgroundColor: duwaTheme.surfaceHighest,
                          child: Text(
                            p.avatarEmoji ?? p.avatarInitials,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        backgroundColor: duwaTheme.surfaceLight,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: duwaTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'UPCOMING SESSIONS (${squadUpcoming.length})',
                    style: TextStyle(
                      color: duwaTheme.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (squadUpcoming.isEmpty)
                    Text('No upcoming sessions planned.', style: TextStyle(color: duwaTheme.textMuted, fontSize: 12))
                  else
                    ...squadUpcoming.map((s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(s.selectedGame?.emoji ?? '🎮', style: const TextStyle(fontSize: 22)),
                          title: Text(s.title, style: TextStyle(color: duwaTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          subtitle: Text('${s.formattedDate} · ${s.formattedTime}', style: TextStyle(color: duwaTheme.textMuted, fontSize: 11)),
                        )),
                  const SizedBox(height: 20),
                  Text(
                    'PAST SESSIONS (${squadPast.length})',
                    style: TextStyle(
                      color: duwaTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (squadPast.isEmpty)
                    Text('No past sessions recorded.', style: TextStyle(color: duwaTheme.textMuted, fontSize: 12))
                  else
                    ...squadPast.map((s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(s.selectedGame?.emoji ?? '🎮', style: const TextStyle(fontSize: 20)),
                          title: Text(s.title, style: TextStyle(color: duwaTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('${s.formattedDate} · ${s.historyHighlight ?? "Completed"}', style: TextStyle(color: duwaTheme.textMuted, fontSize: 11)),
                        )),
                  const SizedBox(height: 26),
                  DuwaButton(
                    label: 'Invite Teammates to ${g.name}',
                    icon: Icons.person_add_alt_1_rounded,
                    isFullWidth: true,
                    onPressed: () => _showInviteSquadSheet(context, g),
                  ),
                  const SizedBox(height: 10),
                  DuwaButton(
                    label: 'Plan a session with ${g.name}',
                    icon: Icons.calendar_month_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      onPlanGameNightForGroup(g);
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteSquad(context, ctx, g),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    label: const Text('Delete Squad', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withAlpha(80)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInviteSquadSheet(BuildContext context, GamerGroupModel initialGroup) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: duwaTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final squad = groupsVm.groups.firstWhere((x) => x.id == initialGroup.id, orElse: () => initialGroup);
            final inviteCode = 'SQ-${squad.id.toUpperCase().replaceAll('-', '')}';
            final inviteLink = 'https://duwa.app/squad/${squad.id}';
            final crewNames = squad.members.map((m) => m.name.replaceAll(' (You)', '')).join(', ');

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: duwaTheme.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: duwaTheme.primaryAccent.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_add_alt_1_rounded, color: duwaTheme.primaryAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite to ${squad.name}',
                                style: TextStyle(
                                  color: duwaTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Add directly or dispatch a squad invite',
                                style: TextStyle(color: duwaTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: IN-APP DIRECT ADD
                    Text(
                      'ADD SQUAD MEMBER',
                      style: TextStyle(
                        color: duwaTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: TextStyle(color: duwaTheme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Enter gamer tag or name',
                              hintStyle: TextStyle(color: duwaTheme.textMuted, fontSize: 13),
                              prefixIcon: Icon(Icons.alternate_email_rounded, color: duwaTheme.textMuted, size: 18),
                              filled: true,
                              fillColor: duwaTheme.surfaceLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: duwaTheme.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: duwaTheme.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: duwaTheme.primaryAccent, width: 1.5),
                              ),
                            ),
                            onSubmitted: (val) async {
                              final name = val.trim();
                              if (name.isNotEmpty) {
                                final added = await groupsVm.addMemberToSquad(squadId: squad.id, memberName: name);
                                if (added) {
                                  controller.clear();
                                  setSheetState(() {});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added $name to ${squad.name}!')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        BouncyTap(
                          onTap: () async {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              final added = await groupsVm.addMemberToSquad(squadId: squad.id, memberName: name);
                              if (added) {
                                controller.clear();
                                setSheetState(() {});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added $name to ${squad.name}!')),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$name is already in ${squad.name}')),
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: duwaTheme.primaryAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick-add suggestions
                    Text(
                      'SUGGESTED GAMERS',
                      style: TextStyle(
                        color: duwaTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: GroupsViewModel.suggestedGamers.map((s) {
                        final alreadyIn = squad.members.any((m) => m.name.toLowerCase() == s['name']!.toLowerCase());
                        return InkWell(
                          onTap: alreadyIn
                              ? null
                              : () async {
                                  final added = await groupsVm.addMemberToSquad(
                                    squadId: squad.id,
                                    memberName: s['name']!,
                                    username: s['tag'],
                                    avatarEmoji: s['emoji'],
                                  );
                                  if (added) {
                                    setSheetState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Added ${s['name']} to ${squad.name}!')),
                                      );
                                    }
                                  }
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: alreadyIn ? duwaTheme.surfaceHighest.withAlpha(80) : duwaTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: alreadyIn ? Colors.transparent : duwaTheme.cardBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s['emoji'] ?? '🎮', style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 5),
                                Text(
                                  s['name']!,
                                  style: TextStyle(
                                    color: alreadyIn ? duwaTheme.textMuted : duwaTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  alreadyIn ? Icons.check : Icons.add,
                                  size: 13,
                                  color: alreadyIn ? duwaTheme.textMuted : duwaTheme.primaryAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // SECTION 2: SOCIAL SHARE DISPATCH
                    Text(
                      'SHARE SQUAD INVITE',
                      style: TextStyle(
                        color: duwaTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Preview Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: duwaTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: duwaTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mark_email_read_rounded, size: 16, color: duwaTheme.primaryAccent),
                              const SizedBox(width: 6),
                              Text(
                                'Invite Message Preview',
                                style: TextStyle(
                                  color: duwaTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '🎲 Join our squad "${squad.name}" on DUWA!\n👥 Crew: $crewNames\n🔑 Squad Code: $inviteCode\n🔗 $inviteLink',
                            style: TextStyle(
                              color: duwaTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Share Buttons Row
                    Row(
                      children: [
                        // WhatsApp
                        Expanded(
                          child: BouncyTap(
                            onTap: () {
                              final text = '🎲 Join our squad *${squad.name}* on DUWA!\n👥 Current Crew: $crewNames\n🔑 Squad Code: $inviteCode\n🔗 $inviteLink';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied invite formatted for WhatsApp!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF25D366).withAlpha(120)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'WhatsApp',
                                    style: TextStyle(
                                      color: Color(0xFF25D366),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Discord
                        Expanded(
                          child: BouncyTap(
                            onTap: () {
                              final text = '🎲 **Join squad "${squad.name}" on DUWA!**\n> 👥 Current Crew: $crewNames\n> 🔑 Code: `$inviteCode`\n> 🔗 $inviteLink';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied invite formatted for Discord!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5865F2).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF5865F2).withAlpha(120)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.forum_rounded, color: Color(0xFF5865F2), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Discord',
                                    style: TextStyle(
                                      color: Color(0xFF5865F2),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Copy Link
                        Expanded(
                          child: BouncyTap(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: inviteLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Squad invite link copied!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: duwaTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: duwaTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link_rounded, color: duwaTheme.textPrimary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy Link',
                                    style: TextStyle(
                                      color: duwaTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
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
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSquad(BuildContext context, BuildContext? bottomSheetContext, GamerGroupModel g) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: duwaTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Squad?',
          style: TextStyle(color: duwaTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete "${g.name}"? This action cannot be undone.',
          style: TextStyle(color: duwaTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Cancel', style: TextStyle(color: duwaTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              if (bottomSheetContext != null && Navigator.canPop(bottomSheetContext)) {
                Navigator.pop(bottomSheetContext);
              }
              groupsVm.deleteSquad(g.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Squad "${g.name}" deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _joinWithCode(BuildContext context) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: duwaTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Join Squad with Code',
              style: TextStyle(color: duwaTheme.textPrimary, fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the squad invite code (e.g. SQ-XXXX)',
                  style: TextStyle(color: duwaTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: duwaTheme.textPrimary, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'SQ-XXXX',
                    hintStyle: TextStyle(color: duwaTheme.textMuted),
                    filled: true,
                    fillColor: duwaTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: duwaTheme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: duwaTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final code = controller.text.trim();
                        if (code.isEmpty) {
                          setDialogState(() => errorMessage = 'Please enter an invite code');
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        final squad = await groupsVm.joinSquadByCode(code);
                        if (!dialogCtx.mounted) return;

                        if (squad != null) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Joined ${squad.name}! 🎮')),
                          );
                          _showSquadDetail(context, squad);
                        } else {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = 'Squad not found! Check code with your crew.';
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Join Squad'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createSquad(BuildContext context) {
    final name = TextEditingController();
    final tagline = TextEditingController();
    String emoji = '🎮';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: duwaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a squad',
              style: TextStyle(
                color: duwaTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Squad name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagline,
              decoration: const InputDecoration(labelText: 'What do you play together?'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: emoji,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: const ['🎮', '🎲', '🍕', '🔥', '🚀', '👾', '🏆']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => emoji = v ?? emoji,
            ),
            const SizedBox(height: 18),
            DuwaButton(
              label: 'Create squad',
              isFullWidth: true,
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                groupsVm.addGroup(
                  name: name.text.trim(),
                  tagline: tagline.text.trim().isEmpty
                      ? 'Gaming sessions with friends'
                      : tagline.text.trim(),
                  emoji: emoji,
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
