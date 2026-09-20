import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/core/theme/duwa_theme.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/services/calendar_service.dart';
import 'package:duwa/views/details/calendar_export_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameNightModel sampleSession;
  late CalendarService calendarService;

  setUp(() {
    calendarService = CalendarService();
    const testPlayers = [
      PlayerModel(id: 'p1', name: 'Alex (You)', username: 'alex', avatarInitials: 'AY', avatarColorIndex: 0, rsvp: RSVPStatus.going),
      PlayerModel(id: 'p2', name: 'Jordan', username: 'jordan', avatarInitials: 'JD', avatarColorIndex: 1, rsvp: RSVPStatus.going),
      PlayerModel(id: 'p3', name: 'Sam', username: 'sam', avatarInitials: 'SM', avatarColorIndex: 2, rsvp: RSVPStatus.maybe),
    ];

    sampleSession = GameNightModel(
      id: 'session-cal-1',
      title: 'Friday Night Cyberpunk LAN',
      group: const GamerGroupModel(
        id: 'group-night-crawlers',
        name: 'Night Crawlers',
        tagline: 'Friday Night Regulars',
        iconEmoji: '🌙',
        members: testPlayers,
      ),
      scheduledDateTime: DateTime.utc(2026, 10, 15, 20, 0), // 8:00 PM UTC
      formattedDate: 'Fri, Oct 15',
      formattedTime: '8:00 PM',
      status: GameNightStatus.ready,
      selectedGame: const GameModel(
        id: 'g-helldivers-2',
        title: 'Helldivers 2',
        genre: 'Co-op Shooter',
        emoji: '🚀',
        bannerGradientStart: '#FF5E1E',
        bannerGradientEnd: '#FFA114',
      ),
      organizerName: 'Alex Mercer',
      roomCode: 'SQUAD99',
      location: const LocationPrepModel(
        name: 'Discord Voice #Alpha',
        detail: 'bit.ly/squad-voice',
      ),
      players: testPlayers,
      checklist: const [
        ChecklistItemModel(id: 'b1', title: 'Microphone Check', isDone: true, assignedTo: 'Alex'),
        ChecklistItemModel(id: 'b2', title: 'Update game patch', isDone: false),
      ],
    );
  });

  group('CalendarService Unit Tests', () {
    test('formatUtcForCalendar formats DateTime to yyyyMMddTHHmmssZ', () {
      final dt = DateTime.utc(2026, 10, 15, 20, 0, 0);
      final formatted = CalendarService.formatUtcForCalendar(dt);
      expect(formatted, equals('20261015T200000Z'));
    });

    test('buildEventTitle prioritizes selected game title', () {
      final title = calendarService.buildEventTitle(sampleSession);
      expect(title, contains('Helldivers 2'));
      expect(title, contains('Night Crawlers'));
    });

    test('buildEventDescription contains squad, game, location, roster, and room code', () {
      final desc = calendarService.buildEventDescription(sampleSession);
      expect(desc, contains('Friday Night Cyberpunk LAN'));
      expect(desc, contains('Night Crawlers'));
      expect(desc, contains('Discord Voice #Alpha'));
      expect(desc, contains('Alex (You)'));
      expect(desc, contains('Jordan'));
      expect(desc, contains('#SQUAD99'));
      expect(desc, contains('Planned with DUWA'));
    });

    test('generateGoogleCalendarUrl creates valid template link with dates', () {
      final url = calendarService.generateGoogleCalendarUrl(sampleSession);
      expect(url, startsWith('https://calendar.google.com/calendar/render?'));
      expect(url, contains('action=TEMPLATE'));
      expect(url, contains('dates=20261015T200000Z%2F20261015T230000Z'));
      expect(url, contains('Helldivers+2'));
      expect(url, contains('Night+Crawlers'));
    });

    test('generateOutlookCalendarUrl creates valid compose link', () {
      final url = calendarService.generateOutlookCalendarUrl(sampleSession);
      expect(url, startsWith('https://outlook.live.com/calendar/0/deeplink/compose?'));
      expect(url, contains('rru=addevent'));
      expect(url, contains('2026-10-15T20%3A00%3A00.000Z'));
    });

    test('generateIcsContent generates RFC-5545 compliant iCalendar string', () {
      final ics = calendarService.generateIcsContent(sampleSession);
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//DUWA//Game Night Planner//EN'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('UID:session-cal-1-'));
      expect(ics, contains('DTSTART:20261015T200000Z'));
      expect(ics, contains('DTEND:20261015T230000Z'));
      expect(ics, contains('SUMMARY:🎮 Game Night: Helldivers 2 (Night Crawlers)'));
      expect(ics, contains('LOCATION:Discord Voice #Alpha'));
      expect(ics, contains('STATUS:CONFIRMED'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });
  });

  group('CalendarExportSheet Widget Tests', () {
    testWidgets('CalendarExportSheet renders all export action options', (tester) async {
      final theme = DuwaThemeData.obsidianVoid();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CalendarExportSheet(
              gameNight: sampleSession,
              duwaTheme: theme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and session details
      expect(find.text('Add to Calendar'), findsOneWidget);
      expect(find.text('Lock it in so nobody double-books game night.'), findsOneWidget);
      expect(find.text('Friday Night Cyberpunk LAN'), findsOneWidget);

      // Check action options (Outlook and .ics removed per UX refinement)
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Copy 1-Tap Calendar Link'), findsOneWidget);
      expect(find.text('Outlook Web Calendar'), findsNothing);
      expect(find.text('Copy iCal (.ics) Event'), findsNothing);
    });

    testWidgets('Tapping Copy 1-Tap Calendar Link copies link to clipboard', (tester) async {
      final theme = DuwaThemeData.obsidianVoid();

      // Mock clipboard channel
      String? copiedString;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final args = methodCall.arguments as Map<dynamic, dynamic>?;
          copiedString = args?['text'] as String?;
          return null;
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CalendarExportSheet(
              gameNight: sampleSession,
              duwaTheme: theme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Copy 1-Tap Calendar Link
      await tester.tap(find.text('Copy 1-Tap Calendar Link'));
      await tester.pump();

      expect(copiedString, isNotNull);
      expect(copiedString, contains('calendar.google.com/calendar/render'));
      expect(find.text('1-Tap Calendar link copied! Ready to share. 🔗'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
