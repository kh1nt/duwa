import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_night_model.dart';
import '../models/group_model.dart';

/// Service providing calendar export and deep-link scheduling for squad game nights.
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  /// Default session duration if not specified
  static const Duration defaultDuration = Duration(hours: 3);

  /// Helper to get effective DateTime for calendar export
  DateTime getSessionDateTime(GameNightModel session) {
    return session.scheduledDateTime ?? DateTime.now();
  }

  /// Formats a DateTime into UTC string format required by Google Calendar and iCal (yyyyMMddTHHmmssZ)
  static String formatUtcForCalendar(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4, '0')}'
        '${u.month.toString().padLeft(2, '0')}'
        '${u.day.toString().padLeft(2, '0')}T'
        '${u.hour.toString().padLeft(2, '0')}'
        '${u.minute.toString().padLeft(2, '0')}'
        '${u.second.toString().padLeft(2, '0')}Z';
  }

  /// Builds a human-readable title for the calendar event
  String buildEventTitle(GameNightModel session) {
    final gameTitle = session.selectedGame?.title;
    if (gameTitle != null && gameTitle.isNotEmpty) {
      return '🎮 Game Night: $gameTitle (${session.group.name})';
    }
    return '🎮 Game Night: ${session.title} (${session.group.name})';
  }

  /// Builds the rich description body for the calendar event
  String buildEventDescription(GameNightModel session) {
    final buffer = StringBuffer();
    buffer.writeln('🎮 ${session.title}');
    buffer.writeln('Squad: ${session.group.name}');
    if (session.organizerName != null && session.organizerName!.isNotEmpty) {
      buffer.writeln('Organized by: ${session.organizerName}');
    }

    if (session.selectedGame != null) {
      buffer.writeln('Game: ${session.selectedGame!.title} (${session.selectedGame!.genre})');
    } else if (session.votingGames.isNotEmpty) {
      buffer.writeln('Voting Ballot: ${session.votingGames.map((g) => g.title).join(", ")}');
    }

    if (session.location != null && session.location!.name.isNotEmpty) {
      buffer.writeln('Voice / Venue: ${session.location!.name}${session.location!.detail != null ? " (${session.location!.detail})" : ""}');
    }

    final confirmedPlayers = session.players
        .where((p) => p.rsvp == RSVPStatus.going)
        .map((p) => p.name)
        .toList();
    if (confirmedPlayers.isNotEmpty) {
      buffer.writeln('Confirmed Lineup (${confirmedPlayers.length}): ${confirmedPlayers.join(", ")}');
    }

    if (session.checklist.isNotEmpty) {
      final claimed = session.checklist.where((b) => b.isDone || (b.assignedTo != null && b.assignedTo!.isNotEmpty)).length;
      buffer.writeln('Preparation: $claimed/${session.checklist.length} items ready');
    }

    buffer.writeln('Room Code: #${session.displayRoomCode}');
    buffer.writeln('Planned with DUWA');
    return buffer.toString();
  }

  /// Generates a pre-filled Google Calendar web link
  String generateGoogleCalendarUrl(GameNightModel session) {
    final sessionDt = getSessionDateTime(session);
    final startUtc = formatUtcForCalendar(sessionDt);
    final endUtc = formatUtcForCalendar(sessionDt.add(defaultDuration));
    final title = buildEventTitle(session);
    final details = buildEventDescription(session);
    final location = session.location?.name ?? 'Discord Voice Lounge';

    final query = <String, String>{
      'action': 'TEMPLATE',
      'text': title,
      'dates': '$startUtc/$endUtc',
      'details': details,
      'location': location,
    };

    final uri = Uri.https('calendar.google.com', '/calendar/render', query);
    return uri.toString();
  }

  /// Generates a pre-filled Outlook Calendar compose web link
  String generateOutlookCalendarUrl(GameNightModel session) {
    final sessionDt = getSessionDateTime(session);
    final start = sessionDt.toUtc().toIso8601String();
    final end = sessionDt.add(defaultDuration).toUtc().toIso8601String();
    final title = buildEventTitle(session);
    final details = buildEventDescription(session);
    final location = session.location?.name ?? 'Discord Voice Lounge';

    final query = <String, String>{
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': title,
      'startdt': start,
      'enddt': end,
      'body': details,
      'location': location,
    };

    final uri = Uri.https('outlook.live.com', '/calendar/0/deeplink/compose', query);
    return uri.toString();
  }

  /// Generates an RFC-5545 compliant iCalendar (.ics) string
  String generateIcsContent(GameNightModel session) {
    final sessionDt = getSessionDateTime(session);
    final nowUtc = formatUtcForCalendar(DateTime.now());
    final startUtc = formatUtcForCalendar(sessionDt);
    final endUtc = formatUtcForCalendar(sessionDt.add(defaultDuration));
    final title = _escapeIcsText(buildEventTitle(session));
    final description = _escapeIcsText(buildEventDescription(session));
    final location = _escapeIcsText(session.location?.name ?? 'Discord Voice Lounge');

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//DUWA//Game Night Planner//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${session.id}-${sessionDt.millisecondsSinceEpoch}@duwa.app',
      'DTSTAMP:$nowUtc',
      'DTSTART:$startUtc',
      'DTEND:$endUtc',
      'SUMMARY:$title',
      'DESCRIPTION:$description',
      'LOCATION:$location',
      'STATUS:CONFIRMED',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');
  }

  /// Escapes special characters for RFC-5545 format
  static String _escapeIcsText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n');
  }

  /// Launches Google Calendar in external browser or calendar app
  Future<bool> launchGoogleCalendar(GameNightModel session) async {
    try {
      final url = Uri.parse(generateGoogleCalendarUrl(session));
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching Google Calendar: $e');
      return false;
    }
  }

  /// Launches Outlook Calendar in external browser
  Future<bool> launchOutlookCalendar(GameNightModel session) async {
    try {
      final url = Uri.parse(generateOutlookCalendarUrl(session));
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching Outlook Calendar: $e');
      return false;
    }
  }
}
