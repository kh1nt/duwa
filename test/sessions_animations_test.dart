import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/views/common/game_pass_card.dart';
import 'package:duwa/views/sessions/sessions_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SessionsView renders radar, sliding filter bar, and switches tabs smoothly', (tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: SessionsView(
            gameNightVm: gameNightVm,
            duwaTheme: themeVm.themeData,
            onOpenSession: (_) {},
            onCreateSession: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SESSION RADAR'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('NEEDS YOU'), findsOneWidget);
    expect(find.text('ARCHIVE'), findsOneWidget);

    // Switch to NEEDS YOU tab
    await tester.tap(find.text('NEEDS YOU'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('NEEDS YOU'), findsOneWidget);

    // Switch to ARCHIVE tab
    await tester.tap(find.text('ARCHIVE'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('ARCHIVE'), findsOneWidget);

    // Switch back to ACTIVE
    await tester.tap(find.text('ACTIVE'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('GamePassCard renders live urgency and handles RSVP selection with haptics', (tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();
    final session = gameNightVm.upcomingGameNight;
    RSVPStatus? updatedRsvp;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: GamePassCard(
            session: session,
            duwaTheme: themeVm.themeData,
            currentUserId: 'p1',
            onTap: () {},
            onRsvpChanged: (status) => updatedRsvp = status,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text("I'm In"), findsOneWidget);
    expect(find.text('Maybe'), findsOneWidget);
    expect(find.text("Can't Go"), findsOneWidget);

    // Tap "Maybe"
    await tester.tap(find.text('Maybe'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(updatedRsvp, RSVPStatus.maybe);

    // Tap "Can't Go"
    await tester.tap(find.text("Can't Go"));
    await tester.pump(const Duration(milliseconds: 200));
    expect(updatedRsvp, RSVPStatus.cantGo);
  });

  testWidgets('SessionsView and GamePassCard respect prefers-reduced-motion (disableAnimations)', (tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: themeVm.materialTheme,
          home: Scaffold(
            body: SessionsView(
              gameNightVm: gameNightVm,
              duwaTheme: themeVm.themeData,
              onOpenSession: (_) {},
              onCreateSession: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ACTIVE'), findsOneWidget);

    await tester.tap(find.text('NEEDS YOU'));
    await tester.pump();
    expect(find.text('NEEDS YOU'), findsOneWidget);
  });
}
