import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../services/calendar_service.dart';
import '../common/bouncy_tap.dart';

/// Modal bottom sheet providing 1-tap calendar scheduling and iCal exports
class CalendarExportSheet extends StatefulWidget {
  final GameNightModel gameNight;
  final DuwaThemeData duwaTheme;

  const CalendarExportSheet({
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
      builder: (_) => CalendarExportSheet(
        gameNight: gameNight,
        duwaTheme: duwaTheme,
      ),
    );
  }

  @override
  State<CalendarExportSheet> createState() => _CalendarExportSheetState();
}

class _CalendarExportSheetState extends State<CalendarExportSheet> {
  final CalendarService _calendarService = CalendarService();
  String? _statusMessage;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String message) {
    HapticFeedback.lightImpact();
    _feedbackTimer?.cancel();
    setState(() {
      _statusMessage = message;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (_statusMessage == message) _statusMessage = null;
        });
      }
    });
  }

  Future<void> _handleGoogleCalendar() async {
    final launched = await _calendarService.launchGoogleCalendar(widget.gameNight);
    if (!launched) {
      // Fallback to copy link
      final url = _calendarService.generateGoogleCalendarUrl(widget.gameNight);
      await Clipboard.setData(ClipboardData(text: url));
      _showFeedback('Copied Google Calendar link to clipboard! 📋');
    } else {
      _showFeedback('Opening Google Calendar... 📅');
    }
  }


  Future<void> _handleCopyLink() async {
    final url = _calendarService.generateGoogleCalendarUrl(widget.gameNight);
    await Clipboard.setData(ClipboardData(text: url));
    _showFeedback('1-Tap Calendar link copied! Ready to share. 🔗');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    final s = widget.gameNight;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: t.cardBorder, width: 1.2),
        boxShadow: DuwaTheme.cozyShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.primaryAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.primaryAccent.withAlpha(80)),
                  ),
                  child: Icon(
                    Icons.edit_calendar_rounded,
                    color: t.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Calendar',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lock it in so nobody double-books game night.',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: t.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Session brief banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.cardBorder),
              ),
              child: Row(
                children: [
                  Text(
                    s.selectedGame?.emoji ?? '🎮',
                    style: const TextStyle(fontSize: 28),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${s.formattedDate} · ${s.formattedTime} · ${s.group.name}',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: DuwaColors.ionMint.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DuwaColors.ionMint.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: DuwaColors.ionMint, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(
                          color: DuwaColors.ionMint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Options
            _buildActionTile(
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF4285F4), // Google Blue
              title: 'Google Calendar',
              subtitle: 'Opens in web browser or calendar app',
              badgeText: 'Instant',
              t: t,
              onTap: _handleGoogleCalendar,
            ),

            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.share_rounded,
              iconColor: DuwaColors.solarFlame,
              title: 'Copy 1-Tap Calendar Link',
              subtitle: 'Share link in Discord or WhatsApp so friends can add it in 1 click',
              badgeText: 'Shareable',
              t: t,
              onTap: _handleCopyLink,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? badgeText,
    required DuwaThemeData t,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                          title,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.primaryAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: t.primaryAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: t.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
