import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/core/theme/duwa_theme.dart';
import 'package:duwa/views/details/edit_game_night_sheet.dart';

void main() {
  group('Core Functional Fixes Tests', () {
    late GameNightViewModel gameNightVm;

    setUp(() {
      gameNightVm = GameNightViewModel.withFixtureData();
    });

    test('GameNightModel correctly tracks voiceChannelUrl and hasVoiceChannel', () {
      const sessionWithoutVoice = GameNightModel(
        id: 'test-session-1',
        title: 'Friday Session',
        group: GameNightViewModel.fridayGamersGroup,
        formattedDate: 'Tonight',
        formattedTime: '8:00 PM',
        status: GameNightStatus.ready,
        players: [],
      );

      expect(sessionWithoutVoice.hasVoiceChannel, false);
      expect(sessionWithoutVoice.voiceChannelUrl, isNull);

      final sessionWithVoice = sessionWithoutVoice.copyWith(
        voiceChannelUrl: 'https://discord.gg/duwa-voice',
      );

      expect(sessionWithVoice.hasVoiceChannel, true);
      expect(sessionWithVoice.voiceChannelUrl, 'https://discord.gg/duwa-voice');
    });

    test('GameNightViewModel.updateSessionDetails modifies session properties', () {
      final initialSession = gameNightVm.allSessions.first;
      final sessionId = initialSession.id;

      final targetDate = DateTime(2026, 10, 25, 21, 30);

      gameNightVm.updateSessionDetails(
        sessionId,
        title: 'Championship Finals',
        description: 'Bring pizza, headsets, and energy drinks!',
        scheduledDateTime: targetDate,
        formattedTime: '9:30 PM',
        voiceChannelUrl: 'https://discord.gg/championship',
        locationName: 'Discord Voice #3',
      );

      final updated = gameNightVm.getSessionById(sessionId);
      expect(updated.title, 'Championship Finals');
      expect(updated.description, 'Bring pizza, headsets, and energy drinks!');
      expect(updated.formattedTime, '9:30 PM');
      expect(updated.voiceChannelUrl, 'https://discord.gg/championship');
      expect(updated.hasVoiceChannel, true);
      expect(updated.location?.name, 'Discord Voice #3');
    });

    test('GameNightViewModel.addChecklistItem dynamically appends items and can be claimed', () {
      final initialSession = gameNightVm.allSessions.first;
      final sessionId = initialSession.id;
      final initialChecklistCount = initialSession.checklist.length;

      const newItem = ChecklistItemModel(
        id: 'snack-item-99',
        title: 'Extra Large Doritos & Salsa',
        isDone: false,
        assignedTo: 'Alex',
      );

      gameNightVm.addChecklistItem(sessionId, newItem);

      final updated = gameNightVm.getSessionById(sessionId);
      expect(updated.checklist.length, initialChecklistCount + 1);

      final added = updated.checklist.firstWhere((i) => i.id == 'snack-item-99');
      expect(added.title, 'Extra Large Doritos & Salsa');
      expect(added.assignedTo, 'Alex');
      expect(added.isDone, false);

      // Toggle status
      gameNightVm.toggleChecklistItem(sessionId, 'snack-item-99');
      final toggled = gameNightVm.getSessionById(sessionId);
      expect(toggled.checklist.firstWhere((i) => i.id == 'snack-item-99').isDone, true);
    });

    testWidgets('EditGameNightSheet renders and updates session details', (tester) async {
      final session = gameNightVm.allSessions.first;
      final theme = DuwaThemeData.obsidianVoid();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EditGameNightSheet.show(
                  context,
                  session: session,
                  gameNightVm: gameNightVm,
                  duwaTheme: theme,
                ),
                child: const Text('Open Edit Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet UI components
      expect(find.text('Edit Session Details'), findsOneWidget);
      expect(find.text('SESSION TITLE'), findsOneWidget);
      expect(find.text('DISCORD VOICE / PARTY LINK'), findsOneWidget);
      expect(find.text('VENUE / LOCATION'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Enter new title
      final titleField = find.widgetWithText(TextField, session.title);
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Renamed Party Session');

      // Ensure Save button is scrolled into view and tap
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final updated = gameNightVm.getSessionById(session.id);
      expect(updated.title, 'Renamed Party Session');
    });
  });
}
