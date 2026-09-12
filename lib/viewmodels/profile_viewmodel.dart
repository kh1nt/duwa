import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_service.dart';

class ProfileViewModel extends ChangeNotifier {
  UserProfileModel _profile = const UserProfileModel(
    id: 'user-default',
    displayName: 'Player',
    handle: '@gamer',
    bio: 'Ready to squad up · Let\'s play 🎮',
    avatarInitials: 'P',
    avatarEmoji: '🎮',
    favoriteGames: [],
    gameNightsHosted: 0,
    gameNightsPlayed: 0,
    isSteamConnected: false,
    steamPersonaName: null,
    steamGamesCount: 0,
    steamFriendCode: null,
    steamLevel: 0,
    steamStatus: null,
    steamRecentHours: 0.0,
    lastSteamSync: null,
  );

  UserProfileModel get profile => _profile;
  bool get isSteamConnected => _profile.isSteamConnected;

  /// Immediately update the in-memory user profile (guaranteed instant UI response)
  void setProfile({
    required String name,
    String? emoji,
    String? uid,
    String? email,
  }) {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Player';
    final cleanEmoji = emoji ?? _profile.avatarEmoji;
    final initials =
        cleanName.length >= 2
            ? cleanName.substring(0, 2).toUpperCase()
            : cleanName.toUpperCase();
    final handle =
        '@${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';

    _profile = _profile.copyWith(
      id: uid ?? _profile.id,
      displayName: cleanName,
      handle: handle,
      avatarInitials: initials,
      avatarEmoji: cleanEmoji,
    );
    notifyListeners();
  }

  Future<void> syncWithFirebaseUser(
    User? user, [
    Map<String, dynamic>? firestoreData,
  ]) async {
    if (user == null) return;
    try {
      final data =
          firestoreData ?? await FirebaseService().getUserProfile(user.uid);
      final currentName = _profile.displayName;
      final rawName =
          user.displayName ??
          data?['displayName'] ??
          (currentName != 'Player'
              ? currentName
              : (user.isAnonymous
                  ? 'Player_${user.uid.substring(0, math.min(4, user.uid.length))}'
                  : (user.email?.split('@').first ?? 'Gamer')));
      final name = rawName.trim().isNotEmpty ? rawName.trim() : 'Player';
      final emoji = (data?['avatarEmoji'] as String?) ?? _profile.avatarEmoji;
      final initials =
          name.length >= 2
              ? name.substring(0, 2).toUpperCase()
              : name.toUpperCase();
      final handle =
          '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';

      _profile = _profile.copyWith(
        id: user.uid,
        displayName: name,
        handle: (data?['handle'] as String?) ?? handle,
        avatarInitials: initials,
        avatarEmoji: emoji,
        bio: (data?['bio'] as String?) ?? _profile.bio,
        photoUrl: (data?['photoUrl'] as String?) ?? _profile.photoUrl,
        favoriteGames:
            (data?['favoriteGames'] as List<dynamic>?)
                ?.map((game) => game.toString())
                .toList() ??
            _profile.favoriteGames,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing profile with user: $e');
    }
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final List<GameModel> _steamCatalog = const [
    GameModel(
      id: 'steam-l4d2',
      title: 'Left 4 Dead 2',
      genre: 'Co-op Zombie Campaign · Valve Classic',
      emoji: '🧟',
      bannerGradientStart: '#1E3A1E',
      bannerGradientEnd: '#0A1A0A',
      isSteamGame: true,
      playerCountRecommendation: '4 players',
      steamAppId: 550,
      playtimeHours: 214,
      recentPlaytimeHours: 8.5,
      squadOwnersCount: 5,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'MA', 'BT'],
      steamDeckStatus: 'verified',
      coopType: '4-Player Online Co-op',
      isInstalled: true,
    ),
    GameModel(
      id: 'steam-lethal',
      title: 'Lethal Company',
      genre: 'Survival Horror · Proximity Chat Comedy',
      emoji: '📦',
      bannerGradientStart: '#854D0E',
      bannerGradientEnd: '#451A03',
      isSteamGame: true,
      playerCountRecommendation: '4-8 players',
      steamAppId: 1966720,
      playtimeHours: 64,
      recentPlaytimeHours: 12.0,
      squadOwnersCount: 5,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'MA', 'BT'],
      steamDeckStatus: 'playable',
      coopType: '4-8 Player Co-op',
      isInstalled: true,
    ),
    GameModel(
      id: 'steam-hd2',
      title: 'Helldivers 2',
      genre: 'Galactic War Third-Person Tactical Shooter',
      emoji: '🚀',
      bannerGradientStart: '#1D4ED8',
      bannerGradientEnd: '#172554',
      isSteamGame: true,
      playerCountRecommendation: '4 players',
      steamAppId: 553850,
      playtimeHours: 148,
      recentPlaytimeHours: 24.5,
      squadOwnersCount: 4,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'MA'],
      steamDeckStatus: 'playable',
      coopType: '4-Player Crossplay Co-op',
      isInstalled: true,
    ),
    GameModel(
      id: 'steam-dota',
      title: 'Dota 2',
      genre: 'MOBA · 5-Stack Turbo & Ranked',
      emoji: '⚔️',
      bannerGradientStart: '#8B0000',
      bannerGradientEnd: '#2F0000',
      isSteamGame: true,
      playerCountRecommendation: '5v5 players',
      steamAppId: 570,
      playtimeHours: 1420,
      recentPlaytimeHours: 16.0,
      squadOwnersCount: 5,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'MA', 'BT'],
      steamDeckStatus: 'playable',
      coopType: '5v5 Competitive MOBA',
      isInstalled: true,
    ),
    GameModel(
      id: 'steam-pa',
      title: 'Party Animals',
      genre: 'Physics Brawler & Party Mini-games',
      emoji: '🐶',
      bannerGradientStart: '#BE185D',
      bannerGradientEnd: '#500724',
      isSteamGame: true,
      playerCountRecommendation: '4-8 players',
      steamAppId: 1260320,
      playtimeHours: 32,
      recentPlaytimeHours: 4.2,
      squadOwnersCount: 5,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'MA', 'BT'],
      steamDeckStatus: 'verified',
      coopType: 'Party Online / Local Split',
      isInstalled: false,
    ),
    GameModel(
      id: 'steam-phasmo',
      title: 'Phasmophobia',
      genre: 'Ghost Hunting Investigation Co-op',
      emoji: '👻',
      bannerGradientStart: '#334155',
      bannerGradientEnd: '#0F172A',
      isSteamGame: true,
      playerCountRecommendation: '4 players',
      steamAppId: 739630,
      playtimeHours: 58,
      recentPlaytimeHours: 0.0,
      squadOwnersCount: 4,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'AG', 'JL', 'BT'],
      steamDeckStatus: 'verified',
      coopType: '4-Player Investigation',
      isInstalled: false,
    ),
    GameModel(
      id: 'steam-valheim',
      title: 'Valheim',
      genre: 'Viking Survival Craft & Boss Raids',
      emoji: '🌲',
      bannerGradientStart: '#14532D',
      bannerGradientEnd: '#052E16',
      isSteamGame: true,
      playerCountRecommendation: '1-10 players',
      steamAppId: 892970,
      playtimeHours: 92,
      recentPlaytimeHours: 0.0,
      squadOwnersCount: 3,
      squadTotalCount: 5,
      squadOwnerAvatars: ['KT', 'MA', 'JL'],
      steamDeckStatus: 'verified',
      coopType: 'Dedicated Server Co-op',
      isInstalled: false,
    ),
  ];

  List<GameModel> get steamCatalog =>
      _profile.isSteamConnected ? _steamCatalog : const [];

  /// Games owned by 100% of current squad members
  List<GameModel> get squadOverlapGames =>
      _profile.isSteamConnected
          ? _steamCatalog.where((g) => g.is100PercentSquadMatch).toList()
          : const [];

  Future<void> syncSteamLibrary() async {
    if (_isSyncing || !_profile.isSteamConnected) return;
    _isSyncing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isSyncing = false;
    _profile = _profile.copyWith(
      lastSteamSync: 'Just now',
      steamGamesCount: _steamCatalog.length,
    );
    notifyListeners();
  }

  void toggleSteamConnection({String? personaName, String? friendCode}) {
    if (_profile.isSteamConnected) {
      _profile = _profile.copyWith(
        isSteamConnected: false,
        steamPersonaName: null,
        steamGamesCount: 0,
        steamFriendCode: null,
        steamLevel: 0,
        steamStatus: null,
        steamRecentHours: 0.0,
      );
    } else {
      _profile = _profile.copyWith(
        isSteamConnected: true,
        steamPersonaName: personaName ?? _profile.displayName,
        steamGamesCount: _steamCatalog.length,
        steamFriendCode: friendCode ?? '87291044',
        steamLevel: 10,
        steamStatus: 'Online',
        steamRecentHours: 4.5,
        lastSteamSync: 'Just now',
      );
    }
    notifyListeners();
    _persistProfile();
  }

  void updateBio(String newBio) {
    _profile = _profile.copyWith(bio: newBio);
    notifyListeners();
    _persistProfile();
  }

  void updatePhotoUrl(String photoUrl) {
    _profile = _profile.copyWith(photoUrl: photoUrl);
    notifyListeners();
    _persistProfile();
  }

  void updateAvatar({
    required String displayName,
    required String handle,
    required String initials,
    required String bio,
    String? avatarEmoji,
    String? photoUrl,
  }) {
    _profile = _profile.copyWith(
      displayName: displayName,
      handle: handle,
      avatarInitials: initials,
      avatarEmoji: avatarEmoji ?? _profile.avatarEmoji,
      photoUrl: photoUrl ?? _profile.photoUrl,
      bio: bio,
    );
    notifyListeners();
    _persistProfile();
  }

  void toggleFavoriteGame(String gameTitle) {
    final list = List<String>.from(_profile.favoriteGames);
    if (list.contains(gameTitle)) {
      list.remove(gameTitle);
    } else {
      list.add(gameTitle);
    }
    _profile = _profile.copyWith(favoriteGames: list);
    notifyListeners();
    _persistProfile();
  }

  void _persistProfile() {
    FirebaseService().saveUserProfile(
      uid: _profile.id,
      displayName: _profile.displayName,
      avatarEmoji: _profile.avatarEmoji,
      steamId: _profile.steamFriendCode,
      handle: _profile.handle,
      bio: _profile.bio,
      photoUrl: _profile.photoUrl,
      favoriteGames: _profile.favoriteGames,
    );
  }
}
