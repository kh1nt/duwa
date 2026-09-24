import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/core/config/cloudinary_config.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/services/cloudinary_service.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/viewmodels/groups_viewmodel.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';
import 'package:duwa/views/profile/profile_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloudinary Pipeline & Config Unit Tests', () {
    test('CloudinaryConfig exposes working default credentials and upload URL', () {
      expect(CloudinaryConfig.defaultCloudName, 'dz4x2mmzc');
      expect(CloudinaryConfig.defaultUploadPreset, 'duwa_preset');
      expect(
        CloudinaryConfig.uploadUrl('dz4x2mmzc'),
        'https://api.cloudinary.com/v1_1/dz4x2mmzc/image/upload',
      );
      expect(
        CloudinaryConfig.isCloudinaryUrl('https://res.cloudinary.com/dz4x2mmzc/image/upload/v1/test.png'),
        isTrue,
      );
      expect(
        CloudinaryConfig.isCloudinaryUrl('https://cdn.cloudflare.steamstatic.com/apps/730.jpg'),
        isFalse,
      );
    });

    test('PreferencesService persists custom Cloudinary credentials and custom games', () async {
      final prefs = PreferencesService();
      await prefs.setCloudinaryCloudName('custom_squad_cloud');
      await prefs.setCloudinaryUploadPreset('custom_preset_xyz');

      expect(prefs.getCloudinaryCloudName(), 'custom_squad_cloud');
      expect(prefs.getCloudinaryUploadPreset(), 'custom_preset_xyz');

      // Test custom games caching
      final sampleGame = {
        'id': 'game-custom-999',
        'title': 'Tekken 8',
        'genre': 'Fighting',
        'emoji': '🥊',
        'bannerGradientStart': '#FF0000',
        'bannerGradientEnd': '#000000',
        'imageUrl': 'https://res.cloudinary.com/dz4x2mmzc/image/upload/v1/tekken.jpg',
      };
      await prefs.setCachedCustomGames([sampleGame]);
      final loaded = prefs.getCachedCustomGames();
      expect(loaded.length, 1);
      expect(loaded.first['title'], 'Tekken 8');
      expect(loaded.first['imageUrl'], contains('res.cloudinary.com'));

      // Clean up
      await prefs.setCloudinaryCloudName(null);
      await prefs.setCloudinaryUploadPreset(null);
    });

    test('CloudinaryService dynamically resolves credentials and resetToDefaults', () {
      final service = CloudinaryService();
      service.resetToDefaults();
      expect(service.cloudName, CloudinaryConfig.defaultCloudName);
      expect(service.uploadPreset, CloudinaryConfig.defaultUploadPreset);
      expect(service.isConfigured, isTrue);

      service.configure(cloudName: 'temp_cloud', uploadPreset: 'temp_preset');
      expect(service.cloudName, 'temp_cloud');
      expect(service.uploadPreset, 'temp_preset');

      service.resetToDefaults();
      expect(service.cloudName, CloudinaryConfig.defaultCloudName);
    });

    test('GameModel.optimizedCoverUrl formats Cloudinary URLs with dynamic transformations', () {
      const cloudinaryGame = GameModel(
        id: 'game-catan',
        title: 'Catan',
        genre: 'Board Game',
        emoji: '🎲',
        bannerGradientStart: '#FF5E1E',
        bannerGradientEnd: '#141722',
        imageUrl: 'https://res.cloudinary.com/dz4x2mmzc/image/upload/v1790104704/catan.png',
      );

      final optimized = cloudinaryGame.optimizedCoverUrl(width: 400, height: 250);
      expect(optimized, isNotNull);
      expect(optimized, contains('f_auto,q_auto'));
      expect(optimized, contains('w_400'));
      expect(optimized, contains('h_250'));
      expect(optimized, contains('c_fill'));

      // Non-cloudinary (e.g. Steam) should remain unchanged
      const steamGame = GameModel(
        id: 'game-steam',
        title: 'Dota 2',
        genre: 'MOBA',
        emoji: '⚔️',
        bannerGradientStart: '#8B0000',
        bannerGradientEnd: '#2F0000',
        steamAppId: 570,
      );
      expect(
        steamGame.optimizedCoverUrl(width: 400, height: 250),
        'https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg',
      );
    });

    test('GameNightViewModel createAndSaveCustomGame sets createdBy and caches locally', () async {
      final vm = GameNightViewModel();
      const testCloudinaryUrl = 'https://res.cloudinary.com/dz4x2mmzc/image/upload/v1/game.jpg';

      final game = await vm.createAndSaveCustomGame(
        title: 'Guilty Gear Strive',
        genre: 'Fighting Anime',
        emoji: '⚡',
        imageUrl: testCloudinaryUrl,
        playerCount: '2 players',
      );

      expect(game.title, 'Guilty Gear Strive');
      expect(game.imageUrl, testCloudinaryUrl);
      expect(game.optimizedCoverUrl(width: 200, height: 150), contains('f_auto,q_auto'));
      expect(vm.catalogGames.any((g) => g.title == 'Guilty Gear Strive'), isTrue);

      final cached = PreferencesService().getCachedCustomGames();
      expect(cached.any((m) => m['title'] == 'Guilty Gear Strive'), isTrue);
    });
  });

  group('ProfileView Cloudinary & Games Showcase Widget Tests', () {
    testWidgets('ProfileView renders Squad Games & Favorites showcase and filter chips', (tester) async {
      final profileVm = ProfileViewModel();
      final themeVm = ThemeViewModel();
      final gameNightVm = GameNightViewModel();
      final groupsVm = GroupsViewModel.withFixtureData();

      await tester.pumpWidget(
        MaterialApp(
          theme: themeVm.materialTheme,
          home: ProfileView(
            profileVm: profileVm,
            themeVm: themeVm,
            gameNightVm: gameNightVm,
            groupsVm: groupsVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section header & Add Game action
      expect(find.text('SQUAD LIBRARY & FAVORITES'), findsOneWidget);
      expect(find.text('Add Game'), findsOneWidget);

      // Check filter chips
      expect(find.textContaining('All Games ('), findsOneWidget);
      expect(find.textContaining('Added by You ('), findsOneWidget);
      expect(find.textContaining('Favorites ('), findsOneWidget);

      // Switch to Favorites tab
      await tester.tap(find.textContaining('Favorites ('));
      await tester.pumpAndSettle();

      // Switch to Added by You tab
      await tester.tap(find.textContaining('Added by You ('));
      await tester.pumpAndSettle();
    });

    testWidgets('ProfileView renders Media Storage Cloudinary tile and opens setup drawer', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profileVm = ProfileViewModel();
      final themeVm = ThemeViewModel();
      final gameNightVm = GameNightViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: themeVm.materialTheme,
          home: ProfileView(
            profileVm: profileVm,
            themeVm: themeVm,
            gameNightVm: gameNightVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cloudinaryTile = find.text('Media Storage (Cloudinary)');
      expect(cloudinaryTile, findsOneWidget);
      expect(find.textContaining('Cloud: dz4x2mmzc'), findsOneWidget);

      // Tap to open Cloudinary settings drawer
      await tester.tap(cloudinaryTile);
      await tester.pumpAndSettle();

      // Verify drawer contents
      expect(find.text('Cloudinary Storage'), findsOneWidget);
      expect(find.text('Test Upload'), findsOneWidget);
      expect(find.text('Save Settings'), findsOneWidget);
      expect(find.text('Reset to App Defaults'), findsOneWidget);
    });

    testWidgets('ProfileView avatar picker opens with Camera and Gallery options', (tester) async {
      final profileVm = ProfileViewModel();
      final themeVm = ThemeViewModel();
      final gameNightVm = GameNightViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: themeVm.materialTheme,
          home: ProfileView(
            profileVm: profileVm,
            themeVm: themeVm,
            gameNightVm: gameNightVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap avatar edit icon
      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      // Verify avatar choices
      expect(find.text('Choose Avatar'), findsOneWidget);
      expect(find.text('Take Photo (Camera)'), findsOneWidget);
      expect(find.text('Upload Photo (Cloudinary)'), findsOneWidget);
      expect(find.textContaining('Use Gamer Monogram'), findsOneWidget);
    });
  });
}
