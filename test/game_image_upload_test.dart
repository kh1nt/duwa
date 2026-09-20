import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/core/theme/duwa_theme.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/services/cloudinary_service.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/views/common/add_game_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Game Model & Cloudinary Image Tests', () {
    test('GameModel displayCoverUrl returns custom imageUrl when provided', () {
      const customGame = GameModel(
        id: 'game-catan',
        title: 'Catan',
        genre: 'Board Game',
        emoji: '🎲',
        bannerGradientStart: '#FF5E1E',
        bannerGradientEnd: '#141722',
        imageUrl: 'https://res.cloudinary.com/duwa/image/upload/v1/games/catan.jpg',
      );

      expect(
        customGame.displayCoverUrl,
        'https://res.cloudinary.com/duwa/image/upload/v1/games/catan.jpg',
      );
    });

    test('GameModel displayCoverUrl falls back to Steam CDN when imageUrl is null', () {
      const steamGame = GameModel(
        id: 'game-helldivers',
        title: 'Helldivers 2',
        genre: 'Co-op Shooter',
        emoji: '🚀',
        bannerGradientStart: '#FF5E1E',
        bannerGradientEnd: '#141722',
        steamAppId: 553850,
      );

      expect(
        steamGame.displayCoverUrl,
        'https://cdn.cloudflare.steamstatic.com/steam/apps/553850/header.jpg',
      );
    });

    test('GameModel serialization preserves imageUrl', () {
      const original = GameModel(
        id: 'game-smash',
        title: 'Super Smash Bros',
        genre: 'Fighting',
        emoji: '🥊',
        bannerGradientStart: '#EF4444',
        bannerGradientEnd: '#7F1D1D',
        imageUrl: 'https://res.cloudinary.com/duwa/image/upload/v1234/smash.png',
      );

      final map = original.toMap();
      expect(map['imageUrl'], 'https://res.cloudinary.com/duwa/image/upload/v1234/smash.png');

      final reconstructed = GameModel.fromMap(map, original.id);
      expect(reconstructed.imageUrl, original.imageUrl);
      expect(reconstructed.displayCoverUrl, original.imageUrl);
    });

    test('CloudinaryService transforms game image URLs with optimization parameters', () {
      final service = CloudinaryService();
      const rawCoverUrl = 'https://res.cloudinary.com/demo/image/upload/v1234567/games/cover.jpg';

      final optimized = service.getOptimizedUrl(
        rawCoverUrl,
        width: 400,
        height: 250,
        quality: 85,
      );

      expect(optimized, contains('f_auto,q_auto'));
      expect(optimized, contains('w_400'));
      expect(optimized, contains('h_250'));
      expect(optimized, contains('c_fill'));
    });

    test('GameNightViewModel createAndSaveCustomGame handles custom imageUrl', () async {
      final vm = GameNightViewModel();
      const testImageUrl = 'https://res.cloudinary.com/duwa/image/upload/v1/games/mario_kart.jpg';

      final newGame = await vm.createAndSaveCustomGame(
        title: 'Mario Kart 8 Deluxe',
        genre: 'Arcade Racing',
        emoji: '🏎️',
        playerCount: '2-4 players',
        imageUrl: testImageUrl,
      );

      expect(newGame.title, 'Mario Kart 8 Deluxe');
      expect(newGame.imageUrl, testImageUrl);
      expect(newGame.displayCoverUrl, testImageUrl);
      expect(vm.catalogGames.first.id, newGame.id);
      expect(vm.catalogGames.first.imageUrl, testImageUrl);
    });
  });

  group('AddGameSheet Widget Tests', () {
    testWidgets('AddGameSheet renders title, Cloudinary upload prompt, and form inputs', (tester) async {
      final vm = GameNightViewModel();
      final theme = DuwaThemeData.obsidianVoid();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddGameSheet(
              gameNightVm: vm,
              duwaTheme: theme,
            ),
          ),
        ),
      );

      expect(find.text('Add Game to Library'), findsOneWidget);
      expect(find.text('GAME COVER PHOTO (CLOUDINARY)'), findsOneWidget);
      expect(find.text('Tap to upload game box art or photo'), findsOneWidget);
      expect(find.text('Stored securely via Cloudinary CDN'), findsOneWidget);
      expect(find.text('GAME BADGE / EMOJI'), findsOneWidget);
      expect(find.text('TITLE'), findsOneWidget);
      expect(find.text('GENRE / CATEGORY'), findsOneWidget);
      expect(find.text('RECOMMENDED PLAYERS'), findsOneWidget);
      expect(find.text('Add to Squad Library'), findsOneWidget);
    });

    testWidgets('AddGameSheet creates custom game without cover gracefully', (tester) async {
      final vm = GameNightViewModel();
      final theme = DuwaThemeData.obsidianVoid();
      GameModel? addedGame;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddGameSheet(
              gameNightVm: vm,
              duwaTheme: theme,
              onGameAdded: (game) => addedGame = game,
            ),
          ),
        ),
      );

      // Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Secret Hitler');
      await tester.enterText(find.byType(TextField).at(1), 'Social Deduction');

      // Scroll into view & tap submit
      final submitButton = find.text('Add to Squad Library');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(addedGame, isNotNull);
      expect(addedGame!.title, 'Secret Hitler');
      expect(addedGame!.genre, 'Social Deduction');
      expect(addedGame!.imageUrl, isNull);
    });
  });
}
