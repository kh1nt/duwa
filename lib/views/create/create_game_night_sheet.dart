import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../common/add_game_sheet.dart';
import '../common/bouncy_tap.dart';
import '../common/celebration_overlay.dart';
import '../common/game_pass_card.dart';

/// Mission Ignition Wizard:
/// Guided cinematic staging experience for planning a gaming adventure:
/// - Step 0: LAUNCH TIMING (Presets like Tonight 8PM, Tomorrow, Weekend Raid)
/// - Step 1: TARGET GAME (Interactive artwork cards, Steam tags, Squad Vote toggle)
/// - Step 2: SQUAD & LOADOUT (Roster, Location/Discord, Bring list)
/// - Step 3: IGNITION (Minted Game Pass, Celebration, Room Code Share)
class CreateGameNightSheet extends StatefulWidget {
  final GameNightViewModel gameNightVm;
  final GroupsViewModel groupsVm;
  final DuwaThemeData duwaTheme;
  final VoidCallback onGameNightConfirmed;

  const CreateGameNightSheet({
    super.key,
    required this.gameNightVm,
    required this.groupsVm,
    required this.duwaTheme,
    required this.onGameNightConfirmed,
  });

  static void show(
    BuildContext context, {
    required GameNightViewModel gameNightVm,
    required GroupsViewModel groupsVm,
    required DuwaThemeData duwaTheme,
    required VoidCallback onGameNightConfirmed,
    GameModel? initialGame,
  }) {
    gameNightVm.startCreationFlow(
      groupsVm.selectedGroup,
      initialGame: initialGame,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: duwaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => CreateGameNightSheet(
            gameNightVm: gameNightVm,
            groupsVm: groupsVm,
            duwaTheme: duwaTheme,
            onGameNightConfirmed: onGameNightConfirmed,
          ),
    );
  }

  @override
  State<CreateGameNightSheet> createState() => _CreateGameNightSheetState();
}

class _CreateGameNightSheetState extends State<CreateGameNightSheet> {
  late final ConfettiController _confettiController;
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _foodController;
  late final TextEditingController _bringItemController;
  bool _isVotingMode = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _titleController = TextEditingController(
      text: widget.gameNightVm.draftTitle,
    );
    _locationController = TextEditingController(
      text: widget.gameNightVm.draftLocation,
    );
    _foodController = TextEditingController(
      text: widget.gameNightVm.draftFoodTitle,
    );
    _bringItemController = TextEditingController();
    _isVotingMode = widget.gameNightVm.draftSelectedGames.length > 1;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _foodController.dispose();
    _bringItemController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameNightVm,
      builder: (context, _) {
        final step = widget.gameNightVm.currentCreationStep;
        final t = widget.duwaTheme;

        // Step 3 = Celebration Screen
        if (step == 3) {
          _confettiController.play();
          HapticFeedback.heavyImpact();
          final mintedPass =
              widget.gameNightVm.lastCreatedSession ??
              widget.gameNightVm.upcomingGameNight;
          final currentUid = widget.gameNightVm.currentUserProfile?.id ?? 'p1';

          return CelebrationOverlay(
            confettiController: _confettiController,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(28),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF10B981),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Session Planned!',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You're all set! ${mintedPass.title} is ready for game night.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Preview of the freshly minted Game Pass
                    GamePassCard(
                      session: mintedPass,
                      duwaTheme: t,
                      currentUserId: currentUid,
                      isCompact: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final code = mintedPass.displayRoomCode;
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Room code $code copied to clipboard!',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text('Share Code'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: t.textPrimary,
                              side: BorderSide(color: t.cardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BouncyTap(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onGameNightConfirmed();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.primaryAccent,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.primaryAccent.withAlpha(90),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Open Session',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Tactical Step Indicator
                _buildStepIndicator(step, t),
                const SizedBox(height: 14),

                // Scrollable content body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: switch (step) {
                      0 => _buildStep0Basics(t),
                      1 => _buildStep1Game(t),
                      2 => _buildStep2Plan(t),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),

                // Bottom Action Bar
                _buildBottomActions(step, t),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== STEP INDICATOR =====================

  Widget _buildStepIndicator(int step, DuwaThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncyTap(
            onTap: () {
              if (step > 0) {
                widget.gameNightVm.prevCreationStep();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.cardBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(step > 0 ? Icons.arrow_back_rounded : Icons.close_rounded, size: 15, color: t.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    step > 0 ? 'Back' : 'Cancel',
                    style: TextStyle(color: t.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'Plan Session',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: i <= step ? t.primaryAccent : t.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 5),
                  Text(
                    'Step ${step + 1} of 3',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Clean gaming icon indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              size: 20,
              color: t.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 0: BASICS & TIMING =====================

  Widget _buildStep0Basics(DuwaThemeData t) {
    final groups = widget.groupsVm.groups;
    final effectiveGroups =
        groups.isNotEmpty
            ? groups
            : [
              const GamerGroupModel(
                id: 'group-default',
                name: 'My Gaming Squad',
                tagline: 'Squad',
                iconEmoji: '🎮',
                members: [],
              ),
            ];
    final currentGroup = widget.gameNightVm.draftGroup ?? effectiveGroups.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When are we playing?',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Select a quick preset or choose your exact date and time.',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),

        // Quick Timing Presets Strip
        _fieldLabel('QUICK TIMING', t),
        const SizedBox(height: 8),
        _buildTimingPresets(t),
        const SizedBox(height: 18),

        // Manual Date and Time Row
        _fieldLabel('DATE & TIME', t),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: BouncyTap(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.gameNightVm.draftDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    widget.gameNightVm.setDraftDateTime(
                      picked,
                      widget.gameNightVm.draftTimeDisplay,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: t.primaryAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDate(widget.gameNightVm.draftDate),
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            BouncyTap(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 20, minute: 0),
                );
                if (time != null) {
                  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                  final min = time.minute.toString().padLeft(2, '0');
                  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
                  widget.gameNightVm.setDraftDateTime(
                    widget.gameNightVm.draftDate,
                    '$hour:$min $period',
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 16,
                      color: t.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.gameNightVm.draftTimeDisplay,
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
          ],
        ),
        const SizedBox(height: 18),

        // Squad Selector
        _fieldLabel('GROUP / SQUAD', t),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: t.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  effectiveGroups.any((g) => g.id == currentGroup.id)
                      ? currentGroup.id
                      : effectiveGroups.first.id,
              isExpanded: true,
              dropdownColor: t.surface,
              icon: Icon(Icons.arrow_drop_down_rounded, color: t.primaryAccent),
              items:
                  effectiveGroups.map((g) {
                    return DropdownMenuItem<String>(
                      value: g.id,
                      child: Row(
                        children: [
                          Text(
                            g.iconEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            g.name,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${g.memberCount} members)',
                            style: TextStyle(color: t.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (groupId) {
                if (groupId != null) {
                  final selected = effectiveGroups.firstWhere(
                    (g) => g.id == groupId,
                  );
                  widget.gameNightVm.selectDraftGroup(selected);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Location / Voice channel
        _fieldLabel('LOCATION OR VOICE CHANNEL', t),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          onChanged: (val) => widget.gameNightVm.setDraftLocation(val),
          style: TextStyle(color: t.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. Discord Voice · Banilad Crib · LAN Cafe',
            prefixIcon: Icon(
              Icons.headset_mic_rounded,
              size: 18,
              color: t.primaryAccent,
            ),
            filled: true,
            fillColor: t.surfaceLight,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimingPresets(DuwaThemeData t) {
    final now = DateTime.now();
    final presets = [
      ('Tonight · 8:00 PM', now, '8:00 PM'),
      ('Tomorrow · 8:00 PM', now.add(const Duration(days: 1)), '8:00 PM'),
      (
        'Weekend Raid · Sat 3:00 PM',
        now.add(
          Duration(days: ((DateTime.saturday - now.weekday) % 7 + 7) % 7),
        ),
        '3:00 PM',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          presets.map((p) {
            return BouncyTap(
              onTap: () {
                widget.gameNightVm.setDraftDateTime(p.$2, p.$3);
                HapticFeedback.selectionClick();
              },
              scaleDown: 0.94,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: t.primaryAccent),
                    const SizedBox(width: 5),
                    Text(
                      p.$1,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // ===================== STEP 1: TARGET GAME =====================

  Widget _buildStep1Game(DuwaThemeData t) {
    final catalog = widget.gameNightVm.catalogGames;
    final selectedGames = widget.gameNightVm.draftSelectedGames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Games',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Pick a game to play, or let the crew vote if undecided.',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Squad Vote Toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                _isVotingMode
                    ? DuwaColors.hyperIndigo.withAlpha(25)
                    : t.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isVotingMode ? DuwaColors.hyperIndigo : t.cardBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.how_to_vote_rounded,
                color: _isVotingMode ? DuwaColors.hyperIndigo : t.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREW VOTE MODE',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _isVotingMode
                          ? 'Pick 2–5 games for everyone to vote on'
                          : 'Single confirmed game',
                      style: TextStyle(color: t.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isVotingMode,
                activeColor: DuwaColors.hyperIndigo,
                onChanged: (val) {
                  setState(() {
                    _isVotingMode = val;
                    if (!val && selectedGames.length > 1) {
                      final first = selectedGames.first;
                      widget.gameNightVm.selectSingleDraftGame(first);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _fieldLabel(
              _isVotingMode
                  ? 'NOMINEES (${selectedGames.length}/5 SELECTED)'
                  : 'GAMES CATALOG',
              t,
            ),
            InkWell(
              onTap: () => _showAddCustomGameSheet(context, t),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 14,
                      color: t.primaryAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ADD GAME',
                      style: TextStyle(
                        color: t.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Game Catalog Tiles
        ...catalog.map((game) {
          final isSelected = selectedGames.any((g) => g.id == game.id);
          final coverUrl = game.optimizedCoverUrl(width: 120, height: 90);

          return BouncyTap(
            onTap: () {
              if (!_isVotingMode) {
                widget.gameNightVm.selectSingleDraftGame(game);
              } else {
                if (isSelected && selectedGames.length <= 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keep at least 1 nominee in vote mode.'),
                    ),
                  );
                  return;
                }
                if (!isSelected && selectedGames.length >= 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Maximum 5 games can be nominated for voting.',
                      ),
                    ),
                  );
                  return;
                }
                widget.gameNightVm.toggleDraftGame(game);
              }
            },
            scaleDown: 0.98,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? t.surfaceHighest : t.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? t.primaryAccent : t.cardBorder,
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        coverUrl != null
                            ? Image.network(
                              coverUrl,
                              width: 58,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 58,
                                    height: 44,
                                    color: t.surface,
                                    alignment: Alignment.center,
                                    child: Text(
                                      game.emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                            )
                            : Container(
                              width: 58,
                              height: 44,
                              color: t.surface,
                              alignment: Alignment.center,
                              child: Text(
                                game.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                game.title,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (game.isSteamGame) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(80),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'STEAM',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.genre,
                          style: TextStyle(color: t.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected ? t.primaryAccent : t.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddCustomGameSheet(BuildContext context, DuwaThemeData t) async {
    final newGame = await AddGameSheet.show(
      context,
      gameNightVm: widget.gameNightVm,
      duwaTheme: t,
    );

    if (newGame != null && mounted) {
      setState(() {
        if (!_isVotingMode) {
          widget.gameNightVm.selectSingleDraftGame(newGame);
        } else {
          if (!widget.gameNightVm.draftSelectedGames.any((g) => g.id == newGame.id)) {
            widget.gameNightVm.toggleDraftGame(newGame);
          }
        }
      });
    }
  }

  // ===================== STEP 2: SQUAD & PLANS =====================

  Widget _buildStep2Plan(DuwaThemeData t) {
    final players = widget.gameNightVm.draftPlayers;
    final checklist = widget.gameNightVm.draftChecklist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Squad & Plans',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Add the little details that help everyone show up ready.',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        _fieldLabel('INVITED CREW (${players.length} PLAYERS)', t),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              players.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: t.surfaceHighest,
                        child: Text(
                          p.avatarEmoji ?? p.avatarInitials,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.name.replaceAll(' (You)', ''),
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 18),

        _fieldLabel('THINGS TO BRING', t),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bringItemController,
                style: TextStyle(color: t.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Extra Controllers, Board Game, Snacks',
                  prefixIcon: Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: t.primaryAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            BouncyTap(
              onTap: () {
                if (_bringItemController.text.trim().isNotEmpty) {
                  widget.gameNightVm.addDraftChecklistItem(
                    _bringItemController.text.trim(),
                  );
                  _bringItemController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: t.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...checklist.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: t.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_box_outline_blank_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      () =>
                          widget.gameNightVm.removeDraftChecklistItem(item.id),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        _fieldLabel('FOOD & DRINKS', t),
        const SizedBox(height: 8),
        TextField(
          controller: _foodController,
          onChanged: (val) => widget.gameNightVm.setDraftFood(val, 'Squad'),
          style: TextStyle(color: t.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. 2 Large Pizzas & Drinks',
            prefixIcon: Icon(
              Icons.local_pizza_outlined,
              size: 18,
              color: t.primaryAccent,
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Plan Summary & Review Card
        _buildPlanReviewCard(t),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlanReviewCard(DuwaThemeData t) {
    final vm = widget.gameNightVm;
    final groupName = vm.draftGroup?.name ?? 'My Gaming Squad';
    final scheduleText = '${_formatDate(vm.draftDate)} at ${vm.draftTimeDisplay}';
    final gameText = _isVotingMode
        ? 'Squad Vote (${vm.draftSelectedGames.length} nominees)'
        : (vm.draftSelectedGames.isNotEmpty ? vm.draftSelectedGames.first.title : 'No game selected');
    final locText = vm.draftLocation.isNotEmpty ? vm.draftLocation : 'Banilad Crib / Discord';
    final foodText = vm.draftFoodTitle.isNotEmpty ? vm.draftFoodTitle : 'BYO Snacks';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, color: t.primaryAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'PLAN REVIEW & SUMMARY',
                style: TextStyle(
                  color: t.primaryAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DuwaColors.ionMint.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'READY TO SCHEDULE',
                  style: TextStyle(
                    color: DuwaColors.ionMint,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _reviewItem('Squad', groupName, Icons.groups_rounded, t),
          _reviewItem('When', scheduleText, Icons.schedule_rounded, t),
          _reviewItem('Game', gameText, Icons.sports_esports_rounded, t),
          _reviewItem('Where', locText, Icons.place_rounded, t),
          _reviewItem('Food & Drinks', foodText, Icons.restaurant_rounded, t),
          if (vm.draftChecklist.isNotEmpty)
            _reviewItem(
              'Loadout',
              '${vm.draftChecklist.length} things to bring planned',
              Icons.inventory_2_rounded,
              t,
            ),
        ],
      ),
    );
  }

  Widget _reviewItem(String label, String value, IconData icon, DuwaThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: t.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: t.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BOTTOM ACTIONS =====================

  Widget _buildBottomActions(int step, DuwaThemeData t) {
    final isLast = step == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          if (step > 0) ...[
            BouncyTap(
              onTap: () => widget.gameNightVm.prevCreationStep(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: t.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: t.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: BouncyTap(
              onTap: () {
                if (isLast) {
                  if (widget.gameNightVm.currentCreationStep == 3) return;
                  widget.gameNightVm.confirmGameNight();
                } else {
                  if (step == 0 && !widget.gameNightVm.isDraftScheduleInFuture) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choose a date and time at least 5 minutes from now.'),
                      ),
                    );
                    return;
                  }
                  if (step == 1) {
                    if (_isVotingMode && widget.gameNightVm.draftSelectedGames.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least 2 games for voting.'),
                        ),
                      );
                      return;
                    }
                    if (!_isVotingMode && widget.gameNightVm.draftSelectedGames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a game to play.'),
                        ),
                      );
                      return;
                    }
                  }
                  widget.gameNightVm.nextCreationStep();
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: t.primaryAccent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: DuwaTheme.cozyShadowLift,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Plan Session' : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
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

  Widget _fieldLabel(String label, DuwaThemeData t) {
    return Text(
      label,
      style: TextStyle(
        color: t.primaryAccent,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
      ),
    );
  }
}
