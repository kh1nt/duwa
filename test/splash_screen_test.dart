import 'package:duwa/core/theme/duwa_theme.dart';
import 'package:duwa/main.dart';
import 'package:duwa/views/splash/duwa_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DuwaSplashScreen Tests', () {
    testWidgets('Renders Gamepad D brand elements and telemetry', (tester) async {
      final theme = DuwaThemeData.obsidianVoid();
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DuwaSplashScreen(
            duwaTheme: theme,
            onComplete: () {
              completed = true;
            },
            minDuration: const Duration(milliseconds: 1000),
          ),
        ),
      );

      // Verify brand title and squad pill
      expect(find.text('DUWA'), findsOneWidget);
      expect(find.text('SQUAD'), findsOneWidget);
      expect(
        find.text('Game sessions without the group chat chaos.'),
        findsOneWidget,
      );

      // Verify telemetry and tap to skip
      expect(find.text('TAP TO SKIP'), findsOneWidget);

      // Check image asset exists
      expect(find.byType(Image), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isFalse);

      // Advance past duration to test auto-complete
      await tester.pump(const Duration(milliseconds: 600));
      expect(completed, isTrue);
    });

    testWidgets('Tap-to-skip triggers instant onComplete callback', (tester) async {
      final theme = DuwaThemeData.obsidianVoid();
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DuwaSplashScreen(
            duwaTheme: theme,
            onComplete: () {
              completed = true;
            },
            minDuration: const Duration(milliseconds: 3000),
          ),
        ),
      );

      expect(completed, isFalse);

      // Tap on screen to skip
      await tester.tap(find.byType(DuwaSplashScreen));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('DuwaApp respects skipSplash flag', (tester) async {
      await tester.pumpWidget(
        const DuwaApp(
          skipSplash: true,
          skipAuth: true,
        ),
      );
      await tester.pumpAndSettle();

      // When splash is skipped and skipAuth is true, DuwaSplashScreen is not shown
      expect(find.byType(DuwaSplashScreen), findsNothing);
    });
  });
}
