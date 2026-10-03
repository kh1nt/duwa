import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../services/calendar_service.dart';
import '../../services/discord_service.dart';
import '../../services/preferences_service.dart';
import '../common/bouncy_tap.dart';
import 'calendar_export_sheet.dart';

enum DispatchFormat { discord, whatsApp }

enum DispatchViewMode { livePreview, rawMarkdown }

class GameNightDispatchSheet extends StatefulWidget {
  final GameNightModel gameNight;
  final DuwaThemeData duwaTheme;

  const GameNightDispatchSheet({
    super.key,
    required this.gameNight,
    required this.duwaTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required GameNightModel gameNight,
    required DuwaThemeData duwaTheme,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameNightDispatchSheet(
        gameNight: gameNight,
        duwaTheme: duwaTheme,
      ),
    );
  }

  @override
  State<GameNightDispatchSheet> createState() => _GameNightDispatchSheetState();
}

class _GameNightDispatchSheetState extends State<GameNightDispatchSheet> {
  DispatchFormat _selectedFormat = DispatchFormat.discord;
  DispatchViewMode _viewMode = DispatchViewMode.livePreview;
  bool _justCopied = false;

  String _generateDiscordText(GameNightModel s) {
    final buffer = StringBuffer();
    buffer.writeln('🎮 **${s.title}** · *${s.group.name}*');
    buffer.writeln('📅 **When**: ${s.formattedDate} at ${s.formattedTime}');
    if (s.location != null && s.location!.name.isNotEmpty) {
      buffer.writeln('📍 **Where**: ${s.location!.name}${s.location!.detail != null && s.location!.detail!.isNotEmpty ? ' (${s.location!.detail})' : ''}');
    }

    if (s.selectedGame != null) {
      buffer.writeln('🕹️ **Game**: **${s.selectedGame!.title}**');
    } else if (s.votingGames.isNotEmpty) {
      buffer.writeln('🗳️ **Voting in Progress**:');
      for (final g in s.votingGames) {
        buffer.writeln('  • ${g.title} (${g.votes} votes)');
      }
    }

    final going = s.goingCount;
    final maybe = s.maybeCount;
    buffer.writeln('👥 **Squad Lineup**: $going In${maybe > 0 ? ', $maybe Maybe' : ''}');


    final unclaimed = s.checklist.where((c) => !c.isDone && (c.assignedTo == null || c.assignedTo!.isEmpty)).map((c) => c.title).toList();
    if (unclaimed.isNotEmpty) {
      buffer.writeln('🎒 **Needs Someone to Bring**: ${unclaimed.join(', ')}');
    } else if (s.checklist.isNotEmpty) {
      buffer.writeln('🎒 **Bring List**: All items claimed! 🎉');
    }

    final calUrl = CalendarService().generateGoogleCalendarUrl(s);
    buffer.writeln('📅 **Add to Calendar**: $calUrl');
    buffer.writeln('');
    buffer.writeln('🔑 **DUWA Room Code**: `${s.displayRoomCode}`');
    buffer.writeln('👉 *Cast your vote and join in DUWA!*');

    return buffer.toString();
  }

  String _generateWhatsAppText(GameNightModel s) {
    final buffer = StringBuffer();
    buffer.writeln('🎮 *DUWA SESSION BRIEFING* 🎮');
    buffer.writeln('*${s.title}* (${s.group.name})');
    buffer.writeln('📅 When: ${s.formattedDate} at ${s.formattedTime}');
    if (s.location != null && s.location!.name.isNotEmpty) {
      buffer.writeln('📍 Where: ${s.location!.name}');
    }


    if (s.selectedGame != null) {
      buffer.writeln('🕹️ Game: ${s.selectedGame!.title}');
    } else if (s.votingGames.isNotEmpty) {
      final gameSummaries = s.votingGames.map((g) => '${g.title} (${g.votes}v)').join(', ');
      buffer.writeln('🗳️ Games on ballot: $gameSummaries');
    }

    buffer.writeln('👥 Confirmed: ${s.goingCount} playing');

    final unclaimed = s.checklist.where((c) => !c.isDone && (c.assignedTo == null || c.assignedTo!.isEmpty)).map((c) => c.title).toList();
    if (unclaimed.isNotEmpty) {
      buffer.writeln('🎒 Still needed: ${unclaimed.join(', ')}');
    }

    final calUrl = CalendarService().generateGoogleCalendarUrl(s);
    buffer.writeln('📅 Add to Calendar: $calUrl');
    buffer.writeln('');
    buffer.writeln('🔑 Room Code: ${s.displayRoomCode}');
    buffer.writeln('Join in the DUWA app to vote & play!');

    return buffer.toString();
  }

  void _copyToClipboard(String text, String confirmationMessage) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justCopied = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(confirmationMessage)),
          ],
        ),
        backgroundColor: _selectedFormat == DispatchFormat.discord
            ? const Color(0xFF5865F2)
            : const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.gameNight;
    final formattedText = _selectedFormat == DispatchFormat.discord
        ? _generateDiscordText(s)
        : _generateWhatsAppText(s);

    // Eye-friendly, soothing dark slate palette specifically tuned for gaming dispatches
    const sheetBg = Color(0xFF131622);
    const containerBg = Color(0xFF0C0E17);
    const borderCol = Color(0xFF23283B);
    const textPrimaryCol = Color(0xFFF1F5F9);
    const textMutedCol = Color(0xFF94A3B8);
    final isDiscord = _selectedFormat == DispatchFormat.discord;
    final platformAccent = isDiscord ? const Color(0xFF5865F2) : const Color(0xFF25D366);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF2D334C), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 36,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333B56),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: platformAccent.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: platformAccent.withAlpha(90)),
                    ),
                    child: Icon(
                      isDiscord ? Icons.tag_rounded : Icons.chat_bubble_rounded,
                      color: platformAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Squad Session Briefing',
                              style: TextStyle(
                                color: textPrimaryCol,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: platformAccent.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isDiscord ? 'DISCORD' : 'WHATSAPP',
                                style: TextStyle(
                                  color: platformAccent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Formatted and ready to paste into your squad chat',
                          style: TextStyle(
                            color: textMutedCol,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BouncyTap(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2336),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol),
                      ),
                      child: const Icon(Icons.close_rounded, color: textMutedCol, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Platform Selector & View Mode Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Dual Platform Switcher Pills
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: containerBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPlatformTabButton(
                              label: 'Discord Format',
                              icon: Icons.tag_rounded,
                              isSelected: _selectedFormat == DispatchFormat.discord,
                              activeColor: const Color(0xFF5865F2),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedFormat = DispatchFormat.discord);
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildPlatformTabButton(
                              label: 'WhatsApp / Chat',
                              icon: Icons.chat_rounded,
                              isSelected: _selectedFormat == DispatchFormat.whatsApp,
                              activeColor: const Color(0xFF25D366),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedFormat = DispatchFormat.whatsApp);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View Mode Toggle (Visual vs Raw)
                  Container(
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeIcon(
                          icon: Icons.preview_rounded,
                          tooltip: 'Visual Card Preview',
                          isActive: _viewMode == DispatchViewMode.livePreview,
                          onTap: () => setState(() => _viewMode = DispatchViewMode.livePreview),
                        ),
                        _buildViewModeIcon(
                          icon: Icons.code_rounded,
                          tooltip: 'Raw Markdown Code',
                          isActive: _viewMode == DispatchViewMode.rawMarkdown,
                          onTap: () => setState(() => _viewMode = DispatchViewMode.rawMarkdown),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content Area: Live Visual Preview OR Raw Markdown
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _viewMode == DispatchViewMode.livePreview
                      ? (isDiscord ? _buildDiscordLivePreview(s) : _buildWhatsAppLivePreview(s))
                      : _buildRawMarkdownViewer(formattedText),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons Dock
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Platform Copy CTA
                  BouncyTap(
                    onTap: () => _copyToClipboard(
                      formattedText,
                      isDiscord
                          ? 'Discord dispatch copied! Paste it into your squad channel. 🎮'
                          : 'Chat dispatch copied! Ready to paste into your squad chat. 🎮',
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDiscord
                              ? [const Color(0xFF5865F2), const Color(0xFF4752C4)]
                              : [const Color(0xFF25D366), const Color(0xFF1EBE5D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: platformAccent.withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _justCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _justCopied
                                ? 'Copied to Clipboard!'
                                : (isDiscord ? 'Copy Discord Dispatch' : 'Copy Chat Dispatch'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Action Row: Room Code + Discord Webhook
                  Row(
                    children: [
                      // Copy Room Code Only
                      Expanded(
                        child: BouncyTap(
                          onTap: () => _copyToClipboard(
                            s.displayRoomCode,
                            'Room code ${s.displayRoomCode} copied! 🔑',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.key_rounded, color: Color(0xFFFFA114), size: 15),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '#${s.displayRoomCode}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: textPrimaryCol,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Add to Calendar
                      Expanded(
                        child: BouncyTap(
                          onTap: () => CalendarExportSheet.show(
                            context,
                            gameNight: s,
                            duwaTheme: widget.duwaTheme,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_calendar_rounded, color: Color(0xFF00F59B), size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'Calendar',
                                  style: TextStyle(
                                    color: textPrimaryCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isDiscord) ...[
                        const SizedBox(width: 8),
                        // Broadcast to Discord Webhook
                        Expanded(
                          child: BouncyTap(
                            onTap: () => _promptAndBroadcastDiscord(context, s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5865F2).withAlpha(35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF5865F2).withAlpha(140)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, color: Color(0xFF8EA1E1), size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    'Webhook',
                                    style: TextStyle(
                                      color: Color(0xFFE0E7FF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== LIVE VISUAL PREVIEWS =====================

  Widget _buildDiscordLivePreview(GameNightModel s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Discord channel banner
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF80848E)),
              const SizedBox(width: 4),
              const Text(
                'squad-announcements',
                style: TextStyle(
                  color: Color(0xFF949BA4),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2D31),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DISCORD PREVIEW',
                  style: TextStyle(color: Color(0xFF80848E), fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bot Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF5865F2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DUWA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BOT',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today at ${s.formattedTime}',
                        style: const TextStyle(color: Color(0xFF949BA4), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Discord Rich Embed Container with Left Blurple Stripe
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2D31),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF35373C)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4px Accent Stripe
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5865F2),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Squad Name
                          Text(
                            '🎮 ${s.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.group.name,
                            style: const TextStyle(
                              color: Color(0xFF949BA4),
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Fields Grid
                          _buildDiscordFieldRow(
                            '📅 When',
                            '${s.formattedDate} at ${s.formattedTime}',
                          ),
                          if (s.location != null && s.location!.name.isNotEmpty)
                            _buildDiscordFieldRow(
                              '📍 Where',
                              s.location!.name,
                            ),
                          if (s.selectedGame != null)
                            _buildDiscordFieldRow(
                              '🕹️ Game',
                              s.selectedGame!.title,
                              highlight: true,
                            )
                          else if (s.votingGames.isNotEmpty)
                            _buildDiscordFieldRow(
                              '🗳️ Voting',
                              s.votingGames.map((g) => '${g.title} (${g.votes}v)').join(', '),
                            ),
                          _buildDiscordFieldRow(
                            '👥 Squad Lineup',
                            '${s.goingCount} In${s.maybeCount > 0 ? ", ${s.maybeCount} Maybe" : ""}',
                          ),

                          const SizedBox(height: 10),

                          // Room Code Codeblock
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1F22),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF383A40)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.key_rounded, size: 14, color: Color(0xFFFFA114)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'DUWA Room Code:',
                                      style: TextStyle(color: Color(0xFF949BA4), fontSize: 11.5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.displayRoomCode,
                                      style: const TextStyle(
                                        color: Color(0xFF00F59B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Join in DUWA',
                                  style: TextStyle(
                                    color: Color(0xFF5865F2),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscordFieldRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, height: 1.3),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Color(0xFF949BA4), fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: highlight ? const Color(0xFF5865F2) : Colors.white,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppLivePreview(GameNightModel s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WhatsApp Channel Sub-Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                s.group.name,
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'WHATSAPP BUBBLE',
                  style: TextStyle(color: Color(0xFF8696A0), fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // WhatsApp Message Bubble (Dark Emerald / Midnight Slate)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B), // Signature WhatsApp Outgoing Bubble
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎮', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Text(
                        'DUWA SESSION BRIEFING',
                        style: TextStyle(
                          color: Color(0xFFE9EDEF),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.title} (${s.group.name})',
                    style: const TextStyle(
                      color: Color(0xFFE9EDEF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('📅 When: ${s.formattedDate} at ${s.formattedTime}', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 12)),
                  if (s.location != null && s.location!.name.isNotEmpty)
                    Text('📍 Where: ${s.location!.name}', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 12)),
                  if (s.selectedGame != null)
                    Text('🕹️ Game: ${s.selectedGame!.title}', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 12, fontWeight: FontWeight.w700))
                  else if (s.votingGames.isNotEmpty)
                    Text('🗳️ Ballot: ${s.votingGames.map((g) => "${g.title} (${g.votes}v)").join(", ")}', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 12)),
                  Text('👥 Confirmed: ${s.goingCount} playing', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔑 Room Code: ${s.displayRoomCode}',
                      style: const TextStyle(
                        color: Color(0xFF00F59B),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join in the DUWA app to vote & play!',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        s.formattedTime,
                        style: const TextStyle(color: Color(0xFF8696A0), fontSize: 10.5),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF53BDEB)), // Read blue ticks
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawMarkdownViewer(String text) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFA5B4FC), // Soft lavender monospace
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ===================== WIDGET HELPERS =====================

  Widget _buildPlatformTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2336) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: activeColor.withAlpha(90)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeIcon({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: BouncyTap(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E2336) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Future<void> _promptAndBroadcastDiscord(BuildContext context, GameNightModel s) async {
    final cachedUrl = PreferencesService().getDiscordWebhookUrl() ?? '';
    final controller = TextEditingController(text: cachedUrl);
    String? validationError;
    bool isBroadcasting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161926),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2C324B)),
          ),
          title: const Row(
            children: [
              Icon(Icons.send_rounded, color: Color(0xFF5865F2), size: 20),
              SizedBox(width: 8),
              Text(
                'Discord Webhook',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your squad channel Webhook URL to broadcast a rich embed directly into Discord:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                enabled: !isBroadcasting,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'https://discord.com/api/webhooks/...',
                  hintStyle: DuwaTheme.blurryHintStyle(widget.duwaTheme, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0D0F18),
                  errorText: validationError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C324B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C324B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5865F2), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isBroadcasting ? null : () => Navigator.pop(dlgCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5865F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isBroadcasting
                  ? null
                  : () async {
                      final url = controller.text.trim();
                      if (url.isEmpty) {
                        setDialogState(() => validationError = 'Please paste a webhook URL');
                        return;
                      }
                      if (!DiscordService().isValidWebhookUrl(url)) {
                        setDialogState(() => validationError = 'URL must start with https://discord.com/api/webhooks/');
                        return;
                      }

                      setDialogState(() {
                        isBroadcasting = true;
                        validationError = null;
                      });

                      bool success = false;
                      try {
                        success = await DiscordService().sendSessionAnnouncement(
                          webhookUrl: url,
                          session: s,
                        );
                      } catch (e) {
                        debugPrint('Discord dispatch error: $e');
                        success = false;
                      }

                      if (!ctx.mounted) return;

                      if (success) {
                        await PreferencesService().setDiscordWebhookUrl(url);
                        if (dlgCtx.mounted) {
                          Navigator.pop(dlgCtx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Session broadcast to Discord channel! 🚀')),
                                ],
                              ),
                              backgroundColor: DuwaColors.ionMint,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isBroadcasting = false;
                          validationError = 'Dispatch failed. Check webhook permissions or URL.';
                        });
                      }
                    },
              child: isBroadcasting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Alert', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
