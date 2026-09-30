import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/game_night_model.dart';
import '../models/group_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

enum StateDemoMode { normal, empty, loading, error }

class GameNightViewModel extends ChangeNotifier {
  StateDemoMode _demoMode = StateDemoMode.normal;
  StateDemoMode get demoMode => _demoMode;

  void setDemoMode(StateDemoMode mode) {
    _demoMode = mode;
    notifyListeners();
  }

  UserProfileModel? _currentUserProfile;
  UserProfileModel? get currentUserProfile => _currentUserProfile;

  List<GameNightModel> _sessions = [];
  final Set<String> _deletedSessionIds = {};
  final Set<String> _joinedSessionIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSubscription;
  StreamSubscription<List<GameModel>>? _gamesSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastCloudDocs = [];

  GameNightViewModel({bool withFixtureData = false}) {
    if (withFixtureData) {
      _sessions = _createFixtureSessions();
    }
    // Only initialise the games catalog here; the session subscription must
    // not start until we have a verified authenticated user (via syncCurrentUser).
    _initGamesCatalog();
  }

  factory GameNightViewModel.withFixtureData() =>
      GameNightViewModel(withFixtureData: true);

  /// Reset sessions state (called on account switch / logout).
  /// Cancels all Firestore subscriptions but does NOT restart them — subscriptions
  /// only restart once syncCurrentUser() is called with a valid user profile.
  void reset({bool withFixtureData = false}) {
    _sessionsSubscription?.cancel();
    _gamesSubscription?.cancel();
    _sessionsSubscription = null;
    _gamesSubscription = null;
    _lastCloudDocs = [];
    _deletedSessionIds.clear();
    _joinedSessionIds.clear();
    _currentUserProfile = null;
    _sessions = withFixtureData ? _createFixtureSessions() : [];
    _initGamesCatalog(); // keep the games catalog fresh (no UID required)
    notifyListeners();
  }

  bool _isUserInSession(Map<String, dynamic> data, String id) {
    if (_joinedSessionIds.contains(id)) return true;

    final currentUid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final currentName = _currentUserProfile?.displayName.trim().toLowerCase() ??
        FirebaseService().currentUser?.displayName?.trim().toLowerCase();

    // If user identity is not yet known, show nothing.
    if ((currentUid == null || currentUid == 'user-default') && currentName == null) {
      return false;
    }

    final createdBy = data['createdBy'] as String?;
    if (createdBy != null && currentUid != null && currentUid != 'user-default' && createdBy == currentUid) {
      return true;
    }

    final playerUids = List<String>.from(data['playerUids'] ?? []);
    if (currentUid != null && currentUid != 'user-default' && playerUids.contains(currentUid)) {
      return true;
    }

    final organizer = (data['organizerName'] as String?)?.trim().toLowerCase();
    if (organizer != null && currentName != null && currentName != 'player' && currentName != 'you' && organizer == currentName) {
      return true;
    }

    final players = (data['players'] as List<dynamic>?) ?? [];
    return players.any((item) {
      if (item is Map<String, dynamic>) {
        final pId = item['id'] as String? ?? item['uid'] as String?;
        if (pId != null && currentUid != null && currentUid != 'user-default' && pId == currentUid) {
          return true;
        }
        final name = (item['name'] as String?)?.replaceAll('(You)', '').trim().toLowerCase();
        if (currentName != null && currentName != 'player' && currentName != 'you' && name == currentName) {
          return true;
        }
        if (_currentUserProfile?.handle != null) {
          final cleanHandle = _currentUserProfile!.handle.toLowerCase().replaceAll('@', '').trim();
          if (cleanHandle.isNotEmpty && cleanHandle != 'gamer' && cleanHandle != 'you' && name == cleanHandle) {
            return true;
          }
        }
      }
      return false;
    });
  }

  void _rebuildSessionsFromDocs() {
    if (_lastCloudDocs.isEmpty) return;

    final userSessionDocs = _lastCloudDocs
        .where((doc) => _isUserInSession(doc.data(), doc.id))
        .toList();

    final cloudSessions = userSessionDocs.map((doc) {
      return _mapFirestoreDocToSession(doc.id, doc.data());
    }).toList();

    final filteredCloud = cloudSessions
        .where((s) => !_deletedSessionIds.contains(s.id))
        .toList();
    final cloudIds = filteredCloud.map((s) => s.id).toSet();

    final pendingLocals = _sessions
        .where((s) =>
            !cloudIds.contains(s.id) &&
            !_deletedSessionIds.contains(s.id) &&
            !s.id.startsWith('gn-1') &&
            !s.id.startsWith('gn-2'))
        .toList();

    _sessions = [...filteredCloud, ...pendingLocals];
  }

  void syncCurrentUser(UserProfileModel profile) {
    _currentUserProfile = profile;

    // If session subscriptions were cancelled (e.g. after reset() on an account
    // switch) and we now have a valid authenticated user, restart them.
    // The stream's first event will call _rebuildSessionsFromDocs() automatically.
    if (_sessionsSubscription == null && profile.id != 'user-default') {
      initFirebaseCatalog();
      // Fall through — still update the "You" label on any locally-cached sessions.
    } else {
      _rebuildSessionsFromDocs();
    }

    final userPlayer = PlayerModel(
      id: profile.id,
      name: '${profile.displayName} (You)',
      username: profile.handle,
      avatarInitials: profile.avatarInitials,
      avatarEmoji: profile.avatarEmoji,
      avatarColorIndex: 0,
      rsvp: RSVPStatus.going,
    );

    for (int i = 0; i < _sessions.length; i++) {
      final updatedPlayers =
          _sessions[i].players.map((p) {
            final normalizedName =
                p.name.replaceAll(' (You)', '').trim().toLowerCase();
            if (p.id == 'p1' ||
                p.id == profile.id ||
                p.name.contains('(You)') ||
                normalizedName == profile.displayName.trim().toLowerCase()) {
              return userPlayer;
            }
            return p;
          }).toList();
      _sessions[i] = _sessions[i].copyWith(players: updatedPlayers);
    }
    notifyListeners();
  }

  // --- CATALOG OF AVAILABLE GAMES (CURATED FOR SQUADS) ---
  static const List<GameModel> _defaultCatalog = [
    GameModel(
      id: 'game-val',
      title: 'Valorant',
      genre: '5v5 Tactical Shooter · Competitive',
      emoji: '🎯',
      bannerGradientStart: '#FF4655',
      bannerGradientEnd: '#0F1923',
      votes: 3,
      voterAvatars: ['M', 'K', 'A'],
      playerCountRecommendation: '5 players',
      imageUrl:
          'https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg', // Apex/Hero shooter style
    ),
    GameModel(
      id: 'game-dota',
      title: 'Dota 2',
      genre: 'MOBA · 5-stack turbo or ranked',
      emoji: '🛡️',
      bannerGradientStart: '#8B0000',
      bannerGradientEnd: '#1F0606',
      votes: 2,
      voterAvatars: ['M', 'D'],
      isSteamGame: true,
      steamAppId: 570,
      playerCountRecommendation: '5v5 players',
    ),
    GameModel(
      id: 'game-oc2',
      title: 'Overcooked! All You Can Eat',
      genre: 'Co-op Chaos · Casual & Fun',
      emoji: '🍳',
      bannerGradientStart: '#F59E0B',
      bannerGradientEnd: '#D97706',
      votes: 1,
      voterAvatars: ['J'],
      isSteamGame: true,
      steamAppId: 1243830,
      playerCountRecommendation: '2-4 players',
    ),
    GameModel(
      id: 'game-itt',
      title: 'It Takes Two',
      genre: 'Co-op Adventure · Story Rich & Cute',
      emoji: '🧸',
      bannerGradientStart: '#EC4899',
      bannerGradientEnd: '#831843',
      votes: 0,
      isSteamGame: true,
      steamAppId: 1426210,
      playerCountRecommendation: '2 players',
    ),
    GameModel(
      id: 'game-pa',
      title: 'Party Animals',
      genre: 'Brawler & Party · Hilarious Physics',
      emoji: '🐶',
      bannerGradientStart: '#F472B6',
      bannerGradientEnd: '#9333EA',
      votes: 1,
      voterAvatars: ['A', 'B'],
      isSteamGame: true,
      steamAppId: 1260320,
      playerCountRecommendation: '4-8 players',
    ),
    GameModel(
      id: 'game-catan',
      title: 'Settlers of Catan',
      genre: 'Board Game Classic · Trading & Strategy',
      emoji: '🎲',
      bannerGradientStart: '#D97706',
      bannerGradientEnd: '#78350F',
      votes: 0,
      isSteamGame: true,
      steamAppId: 544510,
      playerCountRecommendation: '3-4 players',
    ),
    GameModel(
      id: 'game-lethal',
      title: 'Lethal Company',
      genre: 'Horror Co-op · Chaos & Proximity Chat',
      emoji: '🔦',
      bannerGradientStart: '#1E293B',
      bannerGradientEnd: '#090D16',
      votes: 0,
      isSteamGame: true,
      steamAppId: 1966720,
      playerCountRecommendation: '4 players',
    ),
    GameModel(
      id: 'game-hd2',
      title: 'Helldivers 2',
      genre: 'Galactic Co-op PvE Shooter',
      emoji: '🚀',
      bannerGradientStart: '#FBBF24',
      bannerGradientEnd: '#1E1B4B',
      votes: 2,
      isSteamGame: true,
      steamAppId: 553850,
      playerCountRecommendation: '4 players',
    ),
  ];

  static List<GameModel> get defaultCatalog => _defaultCatalog;

  List<GameModel> _catalogGames = List<GameModel>.from(_defaultCatalog);
  List<GameModel> get catalogGames => _catalogGames;

  /// Initialise the games catalog subscription only (no UID required).
  /// Safe to call from the constructor and after reset().
  void _initGamesCatalog() {
    try {
      // 1. Hydrate from locally saved custom games immediately
      final cachedCustomMaps = PreferencesService().getCachedCustomGames();
      if (cachedCustomMaps.isNotEmpty) {
        final cachedCustom = cachedCustomMaps
            .map((m) => GameModel.fromMap(m, m['id'] as String? ?? 'game-${DateTime.now().millisecondsSinceEpoch}'))
            .toList();
        final cachedIds = cachedCustom.map((g) => g.id).toSet();
        final remainingDefaults =
            _defaultCatalog.where((g) => !cachedIds.contains(g.id)).toList();
        _catalogGames = [...cachedCustom, ...remainingDefaults];
      }

      FirebaseService().seedInitialGamesIfEmpty(_defaultCatalog);
      _gamesSubscription?.cancel();
      _gamesSubscription = FirebaseService().streamGames().listen(
        (cloudGames) {
          if (cloudGames.isNotEmpty) {
            // Keep local custom games if not yet in cloud
            final cloudIds = cloudGames.map((g) => g.id).toSet();
            final localCustom = _catalogGames
                .where((g) => (g.imageUrl != null || g.createdBy != null || g.isSteamGame) && !cloudIds.contains(g.id))
                .toList();

            final remainingDefaults =
                _defaultCatalog.where((g) => !cloudIds.contains(g.id)).toList();
            _catalogGames = [...localCustom, ...cloudGames, ...remainingDefaults];
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore games stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Games catalog sync note (offline or test mode): $e');
    }
  }

  void _persistCustomGameLocally(GameModel game) {
    try {
      final existing = PreferencesService().getCachedCustomGames();
      final index = existing.indexWhere((m) => m['id'] == game.id || m['title'] == game.title);
      final gameMap = game.toMap()..['id'] = game.id;
      if (index != -1) {
        existing[index] = gameMap;
      } else {
        existing.insert(0, gameMap);
      }
      PreferencesService().setCachedCustomGames(existing);
    } catch (e) {
      debugPrint('Error caching custom game: $e');
    }
  }

  /// Initialise BOTH the games catalog and the user-scoped session subscription.
  /// Must only be called when a valid authenticated user is available — i.e.
  /// after syncCurrentUser() has been called with a real user profile.
  void initFirebaseCatalog() {
    // Guard: refuse to subscribe to sessions if no authenticated user is known.
    // This prevents the entire sessions collection from being read and shown to
    // whoever happens to be looking at the screen during an account switch.
    final uid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    if (uid == null || uid == 'user-default') {
      debugPrint('initFirebaseCatalog: no authenticated user — session subscription skipped');
      _initGamesCatalog();
      return;
    }

    _initGamesCatalog();

    try {
      _sessionsSubscription?.cancel();
      _sessionsSubscription = FirebaseService().streamGameNights(uid: uid).listen(
        (snapshot) {
          _lastCloudDocs = snapshot.docs;
          _rebuildSessionsFromDocs();
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore game nights stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Sessions live sync note (offline or test mode): $e');
    }
  }

  Future<GameModel> createAndSaveCustomGame({
    required String title,
    required String genre,
    required String emoji,
    String? playerCount,
    String? imageUrl,
  }) async {
    final currentUid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final (start, end) = _generateThemeGradients(genre, title);
    final newGame = GameModel(
      id: 'game-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      genre: genre.trim(),
      emoji: emoji.trim().isNotEmpty ? emoji.trim() : '🎮',
      bannerGradientStart: start,
      bannerGradientEnd: end,
      imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty) ? imageUrl.trim() : null,
      playerCountRecommendation:
          playerCount?.trim().isNotEmpty == true
              ? playerCount!.trim()
              : '2-8 players',
      createdBy: currentUid,
    );

    try {
      final saved = await FirebaseService().addGame(newGame);
      final finalGame = saved ?? newGame;
      _persistCustomGameLocally(finalGame);
      _catalogGames.insert(0, finalGame);
      notifyListeners();
      return finalGame;
    } catch (e) {
      debugPrint('Error saving custom game to Firebase, keeping locally: $e');
      _persistCustomGameLocally(newGame);
      _catalogGames.insert(0, newGame);
      notifyListeners();
      return newGame;
    }
  }

  /// Returns true if the game exists in DUWA's games catalog (by ID, title, or Steam AppId)
  bool isGameInCatalog(GameModel game) {
    return _catalogGames.any(
      (g) =>
          g.id == game.id ||
          g.title.trim().toLowerCase() == game.title.trim().toLowerCase() ||
          (game.steamAppId != null &&
              game.steamAppId! > 0 &&
              g.steamAppId == game.steamAppId),
    );
  }

  /// Returns true if a game is currently nominated in any active voting session
  bool isGameNominatedInActiveSession(GameModel game) {
    final votingIndex = _sessions.indexWhere(
      (s) => s.status == GameNightStatus.voting,
    );
    if (votingIndex == -1) return false;
    final session = _sessions[votingIndex];
    return session.votingGames.any(
      (g) =>
          g.id == game.id ||
          g.title.trim().toLowerCase() == game.title.trim().toLowerCase() ||
          (game.steamAppId != null &&
              game.steamAppId! > 0 &&
              g.steamAppId == game.steamAppId),
    );
  }

  /// Returns true if there is an active session currently in voting mode
  bool get hasActiveVotingSession =>
      _sessions.any((s) => s.status == GameNightStatus.voting);

  /// Adds a game (e.g. from Steam library or external source) directly to the DUWA catalog
  Future<GameModel> addGameToCatalog(GameModel game) async {
    final existingIndex = _catalogGames.indexWhere(
      (g) =>
          g.id == game.id ||
          g.title.trim().toLowerCase() == game.title.trim().toLowerCase() ||
          (game.steamAppId != null &&
              game.steamAppId! > 0 &&
              g.steamAppId == game.steamAppId),
    );
    if (existingIndex != -1) {
      return _catalogGames[existingIndex];
    }

    final currentUid =
        _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final (start, end) = (game.bannerGradientStart.isNotEmpty &&
            game.bannerGradientEnd.isNotEmpty &&
            game.bannerGradientStart != '#1E293B')
        ? (game.bannerGradientStart, game.bannerGradientEnd)
        : _generateThemeGradients(game.genre, game.title);

    final coverArt = (game.imageUrl != null && game.imageUrl!.isNotEmpty)
        ? game.imageUrl
        : (game.steamAppId != null && game.steamAppId! > 0
            ? 'https://cdn.cloudflare.steamstatic.com/steam/apps/${game.steamAppId}/header.jpg'
            : null);

    final gameToSave = game.copyWith(
      createdBy: game.createdBy ?? currentUid,
      bannerGradientStart: start,
      bannerGradientEnd: end,
      imageUrl: coverArt,
      isSteamGame:
          game.isSteamGame || (game.steamAppId != null && game.steamAppId! > 0),
    );

    try {
      final saved = await FirebaseService().addGame(gameToSave);
      final finalGame = saved ?? gameToSave;
      _persistCustomGameLocally(finalGame);
      _catalogGames.insert(0, finalGame);
      notifyListeners();
      return finalGame;
    } catch (e) {
      debugPrint('Error saving game to Firebase, keeping locally: $e');
      _persistCustomGameLocally(gameToSave);
      _catalogGames.insert(0, gameToSave);
      notifyListeners();
      return gameToSave;
    }
  }

  /// Batch imports multiple games into the DUWA catalog
  Future<int> addMultipleGamesToCatalog(List<GameModel> games) async {
    int count = 0;
    for (final game in games) {
      if (!isGameInCatalog(game)) {
        await addGameToCatalog(game);
        count++;
      }
    }
    return count;
  }

  (String, String) _generateThemeGradients(String genre, String title) {
    final lower = '$genre $title'.toLowerCase();
    if (lower.contains('ragnarok') ||
        lower.contains('rpg') ||
        lower.contains('mmo') ||
        lower.contains('fantasy')) {
      return ('#8B5CF6', '#3B0764'); // Magical Amethyst & Deep Void
    }
    if (lower.contains('fight') ||
        lower.contains('smash') ||
        lower.contains('brawl')) {
      return ('#EF4444', '#7F1D1D'); // Crimson Blaze
    }
    if (lower.contains('catan') ||
        lower.contains('board') ||
        lower.contains('strategy')) {
      return ('#D97706', '#78350F'); // Amber Wood
    }
    if (lower.contains('shoot') ||
        lower.contains('fps') ||
        lower.contains('strike') ||
        lower.contains('gun')) {
      return ('#06B6D4', '#083344'); // Cyber Teal
    }
    if (lower.contains('kart') ||
        lower.contains('race') ||
        lower.contains('speed')) {
      return ('#EC4899', '#831843'); // Neon Magenta
    }
    return ('#4F46E5', '#1E1B4B'); // Electric Indigo
  }

  static const GamerGroupModel fridayGamersGroup = GamerGroupModel(
    id: 'group-1',
    name: 'Weekend Squad',
    tagline: '5 members · Valorant & Party',
    iconEmoji: '🎯',
    members: [
      PlayerModel(
        id: 'p1',
        name: 'You',
        username: '@you',
        avatarInitials: 'U',
        avatarEmoji: '🎮',
        avatarColorIndex: 0,
        rsvp: RSVPStatus.going,
      ),
      PlayerModel(
        id: 'p2',
        name: 'Alex',
        username: '@alex_k',
        avatarInitials: 'A',
        avatarColorIndex: 1,
        rsvp: RSVPStatus.going,
      ),
      PlayerModel(
        id: 'p3',
        name: 'Jordan',
        username: '@jordan_m',
        avatarInitials: 'J',
        avatarColorIndex: 2,
        rsvp: RSVPStatus.going,
      ),
      PlayerModel(
        id: 'p4',
        name: 'Sam',
        username: '@sam_t',
        avatarInitials: 'S',
        avatarColorIndex: 4,
        rsvp: RSVPStatus.going,
      ),
    ],
  );

  static const GamerGroupModel weekendSquadGroup = GamerGroupModel(
    id: 'group-2',
    name: 'Co-op Crew',
    tagline: '4 members · Party Games',
    iconEmoji: '🎲',
    members: [
      PlayerModel(
        id: 'p1',
        name: 'You',
        username: '@you',
        avatarInitials: 'U',
        avatarEmoji: '🎮',
        avatarColorIndex: 0,
        rsvp: RSVPStatus.going,
      ),
      PlayerModel(
        id: 'p5',
        name: 'Taylor',
        username: '@taylor_r',
        avatarInitials: 'T',
        avatarColorIndex: 3,
        rsvp: RSVPStatus.going,
      ),
    ],
  );

  static const GameNightModel _placeholderSession = GameNightModel(
    id: 'gn-default',
    title: 'Squad Session',
    group: GamerGroupModel(
      id: 'group-default',
      name: 'Squad',
      tagline: 'Squad',
      iconEmoji: '🎮',
      members: [],
    ),
    formattedDate: 'Upcoming',
    formattedTime: '8:00 PM',
    status: GameNightStatus.ready,
    players: [],
  );

  static List<GameNightModel> _createFixtureSessions() {
    final upcoming = GameNightModel(
      id: 'gn-featured-1',
      title: 'Friday Valorant Session',
      group: fridayGamersGroup,
      organizerName: 'Alex',
      scheduledDateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      formattedDate: 'Friday, Sep 11',
      formattedTime: '8:00 PM',
      status: GameNightStatus.ready,
      selectedGame: const GameModel(
        id: 'game-val',
        title: 'Valorant',
        genre: '5v5 Tactical Shooter · Competitive',
        emoji: '🎯',
        bannerGradientStart: '#FF4655',
        bannerGradientEnd: '#0F1923',
        playerCountRecommendation: '5v5 players',
        imageUrl:
            'https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg',
      ),
      players: const [
        PlayerModel(
          id: 'p2',
          name: 'Alex',
          username: '@alex_k',
          avatarInitials: 'A',
          avatarColorIndex: 1,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p3',
          name: 'Jordan',
          username: '@jordan_m',
          avatarInitials: 'J',
          avatarColorIndex: 2,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p1',
          name: 'You',
          username: '@you',
          avatarInitials: 'U',
          avatarEmoji: '🎮',
          avatarColorIndex: 0,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p4',
          name: 'Sam',
          username: '@sam_t',
          avatarInitials: 'S',
          avatarColorIndex: 4,
          rsvp: RSVPStatus.going,
        ),
      ],
      location: const LocationPrepModel(
        name: "Mark's House",
        detail: 'Banilad, Cebu City (or Discord Voice #1)',
        isConfirmed: true,
      ),
      food: const FoodPrepModel(
        title: 'Pizza (2 Large Pepperoni & Cheese)',
        buyerName: 'Alex',
        isReady: true,
      ),
      drinks: const DrinkPrepModel(
        items: ['Soft drinks', 'Coke Zero', 'Cold Water'],
        isReady: true,
      ),
      checklist: const [
        ChecklistItemModel(
          id: 'c1',
          title: 'Warm up in Range',
          isDone: true,
          assignedTo: 'Alex',
        ),
        ChecklistItemModel(
          id: 'c2',
          title: 'Soft drinks & ice ready',
          isDone: true,
          assignedTo: 'Jordan',
        ),
        ChecklistItemModel(
          id: 'c3',
          title: 'Bring controllers & headsets',
          isDone: false,
          assignedTo: null,
        ),
        ChecklistItemModel(
          id: 'c4',
          title: 'Ethernet hub connected',
          isDone: true,
          assignedTo: 'Alex',
        ),
      ],
      isHost: false,
    );

    final voting = GameNightModel(
      id: 'gn-voting-1',
      title: 'Saturday Hangout Session',
      group: fridayGamersGroup,
      organizerName: 'Alex',
      scheduledDateTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
      formattedDate: 'Saturday, Sep 12',
      formattedTime: '8:00 PM',
      status: GameNightStatus.voting,
      votingGames: const [
        GameModel(
          id: 'game-val',
          title: 'Valorant',
          genre: '5v5 Tactical Shooter',
          emoji: '🎮',
          bannerGradientStart: '#FF4655',
          bannerGradientEnd: '#0F1923',
          votes: 3,
          voterAvatars: ['A', 'J', 'U'],
        ),
        GameModel(
          id: 'game-dota',
          title: 'Dota 2',
          genre: 'MOBA',
          emoji: '🛡️',
          bannerGradientStart: '#8B0000',
          bannerGradientEnd: '#1F0606',
          votes: 2,
          voterAvatars: ['S'],
        ),
        GameModel(
          id: 'game-oc2',
          title: 'Overcooked! 2',
          genre: 'Co-op Chaos',
          emoji: '🍳',
          bannerGradientStart: '#F59E0B',
          bannerGradientEnd: '#D97706',
          votes: 1,
          voterAvatars: ['T'],
        ),
      ],
      userVotedGameId: 'game-val',
      players: const [
        PlayerModel(
          id: 'p2',
          name: 'Alex',
          username: '@alex_k',
          avatarInitials: 'A',
          avatarColorIndex: 1,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p1',
          name: 'You',
          username: '@you',
          avatarInitials: 'U',
          avatarEmoji: '🎮',
          avatarColorIndex: 0,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p3',
          name: 'Jordan',
          username: '@jordan_m',
          avatarInitials: 'J',
          avatarColorIndex: 2,
          rsvp: RSVPStatus.maybe,
        ),
      ],
      checklist: const [
        ChecklistItemModel(
          id: 'vc1',
          title: 'Vote before Friday 6 PM',
          isDone: false,
        ),
        ChecklistItemModel(
          id: 'vc2',
          title: 'Check game updates',
          isDone: true,
          assignedTo: 'You',
        ),
      ],
      isHost: false,
    );

    final past = const GameNightModel(
      id: 'gn-past-1',
      title: 'Overcooked 2 Chaos',
      group: weekendSquadGroup,
      formattedDate: 'Last Tuesday',
      formattedTime: '8:00 PM',
      status: GameNightStatus.completed,
      selectedGame: GameModel(
        id: 'game-oc2',
        title: 'Overcooked! 2',
        genre: 'Co-op Cooking Chaos',
        emoji: '🍳',
        bannerGradientStart: '#F59E0B',
        bannerGradientEnd: '#D97706',
      ),
      players: [
        PlayerModel(
          id: 'p1',
          name: 'You',
          username: '@you',
          avatarInitials: 'U',
          avatarEmoji: '🎮',
          avatarColorIndex: 0,
          rsvp: RSVPStatus.going,
        ),
        PlayerModel(
          id: 'p2',
          name: 'Alex',
          username: '@alex_k',
          avatarInitials: 'A',
          avatarColorIndex: 1,
          rsvp: RSVPStatus.going,
        ),
      ],
      location: LocationPrepModel(name: 'Discord Voice'),
      historyHighlight: 'MVP: You',
      subdetail: 'Last Tuesday • 4 Duwaonon • 3-star streak',
    );

    return [upcoming, voting, past];
  }

  static GameNightModel _mapFirestoreDocToSession(
    String id,
    Map<String, dynamic> data,
  ) {
    final title = (data['title'] as String?) ?? 'Squad Session';
    final roomCode = data['roomCode'] as String?;
    final groupId = (data['groupId'] as String?) ?? 'g1';
    final groupName = (data['groupName'] as String?) ?? 'Squad';
    final statusStr = (data['status'] as String?) ?? 'ready';
    final timeStr = (data['time'] as String?) ?? '8:00 PM';
    final organizerName = data['organizerName'] as String?;

    DateTime? scheduledDate;
    if (data['date'] != null) {
      try {
        final raw = data['date'];
        if (raw is Timestamp) {
          scheduledDate = raw.toDate();
        }
      } catch (_) {}
    }

    final rawNominated = (data['nominatedGames'] as List<dynamic>?) ?? [];
    final nominatedGames =
        rawNominated.map((item) {
          if (item is Map<String, dynamic>) {
            return GameModel(
              id: item['id'] ?? 'g-${item['title']}',
              title: item['title'] ?? 'Game',
              genre: (item['genre'] as String?) ?? 'Squad Game',
              emoji: (item['emoji'] as String?) ?? '🎮',
              bannerGradientStart:
                  (item['bannerGradientStart'] as String?) ?? '#4F46E5',
              bannerGradientEnd:
                  (item['bannerGradientEnd'] as String?) ?? '#1E1B4B',
              votes: item['votes'] ?? 0,
            );
          }
          return const GameModel(
            id: 'g-unknown',
            title: 'Game',
            genre: 'Squad Game',
            emoji: '🎮',
            bannerGradientStart: '#4F46E5',
            bannerGradientEnd: '#1E1B4B',
          );
        }).toList();

    final createdBy = data['createdBy'] as String?;
    final playerUids = List<String>.from(data['playerUids'] ?? []);
    final currentUid = FirebaseService().currentUser?.uid;
    final isHost = (createdBy != null && currentUid != null && currentUid != 'user-default' && createdBy == currentUid);

    final rawPlayers = (data['players'] as List<dynamic>?) ?? [];
    final players =
        rawPlayers.map((item) {
          if (item is Map<String, dynamic>) {
            final name = item['name'] ?? 'Player';
            final rsvpStr = item['rsvp'] ?? 'going';
            final pId = (item['id'] as String?) ?? (item['uid'] as String?) ?? 'p-${name.hashCode}';
            return PlayerModel(
              id: pId,
              name: name,
              username:
                  '@${name.toString().toLowerCase().replaceAll(' ', '_')}',
              avatarInitials:
                  name.toString().isNotEmpty
                      ? name.toString().substring(0, 1).toUpperCase()
                      : 'P',
              avatarColorIndex: (name.hashCode % 6).abs(),
              rsvp:
                  rsvpStr == 'cantGo'
                      ? RSVPStatus.cantGo
                      : (rsvpStr == 'maybe'
                          ? RSVPStatus.maybe
                          : RSVPStatus.going),
            );
          }
          return const PlayerModel(
            id: 'p-anon',
            name: 'Player',
            username: '@player',
            avatarInitials: 'P',
            avatarColorIndex: 0,
          );
        }).toList();

    final isPast = scheduledDate != null &&
        scheduledDate.isBefore(DateTime.now().subtract(const Duration(hours: 4)));
    final GameNightStatus status = isPast
        ? GameNightStatus.completed
        : switch (statusStr) {
            'voting' => GameNightStatus.voting,
            'planning' => GameNightStatus.planning,
            'completed' => GameNightStatus.completed,
            'cancelled' => GameNightStatus.cancelled,
            'ready' =>
              (nominatedGames.length > 1
                  ? GameNightStatus.voting
                  : GameNightStatus.ready),
            _ =>
              (nominatedGames.length > 1
                  ? GameNightStatus.voting
                  : GameNightStatus.ready),
          };

    final isVoting = status == GameNightStatus.voting;

    GameModel? selectedGame;
    if (data['selectedGame'] != null &&
        data['selectedGame'] is Map<String, dynamic>) {
      final sg = data['selectedGame'] as Map<String, dynamic>;
      selectedGame = GameModel(
        id: sg['id'] ?? 'g-sel',
        title: sg['title'] ?? 'Game',
        genre: (sg['genre'] as String?) ?? 'Squad Game',
        emoji: (sg['emoji'] as String?) ?? '🎮',
        bannerGradientStart:
            (sg['bannerGradientStart'] as String?) ?? '#4F46E5',
        bannerGradientEnd: (sg['bannerGradientEnd'] as String?) ?? '#1E1B4B',
      );
    } else if (nominatedGames.isNotEmpty && !isVoting) {
      selectedGame = nominatedGames.first;
    }

    LocationPrepModel? location;
    if (data['location'] != null && data['location'] is Map<String, dynamic>) {
      final loc = data['location'] as Map<String, dynamic>;
      if (loc['name'] != null && loc['name'].toString().isNotEmpty) {
        location = LocationPrepModel(
          name: loc['name'],
          detail: loc['detail'],
          isConfirmed: true,
        );
      }
    }

    FoodPrepModel? food;
    if (data['food'] != null && data['food'] is Map<String, dynamic>) {
      final f = data['food'] as Map<String, dynamic>;
      if (f['title'] != null && f['title'].toString().isNotEmpty) {
        food = FoodPrepModel(
          title: f['title'],
          buyerName: f['buyerName'],
          isReady: true,
        );
      }
    }

    DrinkPrepModel? drinks;
    if (data['drinks'] != null && data['drinks'] is List) {
      final dList = List<String>.from(data['drinks']);
      if (dList.isNotEmpty) {
        drinks = DrinkPrepModel(items: dList, isReady: true);
      }
    }

    final rawChecklist = (data['checklist'] as List<dynamic>?) ?? [];
    final checklist =
        rawChecklist.map((c) {
          if (c is Map<String, dynamic>) {
            return ChecklistItemModel(
              id: c['id'] ?? 'c-${DateTime.now().millisecondsSinceEpoch}',
              title: c['title'] ?? 'Checklist Item',
              isDone: c['isDone'] as bool? ?? false,
              assignedTo: c['assignedTo'] as String?,
            );
          }
          return ChecklistItemModel(id: 'c-0', title: c.toString());
        }).toList();

    return GameNightModel(
      id: id,
      title: title,
      roomCode: roomCode,
      group: GamerGroupModel(
        id: groupId,
        name: groupName,
        tagline: '$groupName Squad',
        iconEmoji: '🎮',
        members: players,
        createdBy: createdBy,
        memberUids: playerUids,
      ),
      scheduledDateTime: scheduledDate,
      formattedDate:
          scheduledDate != null
              ? '${scheduledDate.month}/${scheduledDate.day}'
              : 'Upcoming',
      formattedTime: timeStr,
      status: status,
      selectedGame: selectedGame,
      votingGames: nominatedGames,
      players: players,
      location: location,
      food: food,
      drinks: drinks,
      checklist: checklist,
      organizerName: organizerName,
      isHost: isHost,
      createdBy: createdBy,
      playerUids: playerUids,
      historyHighlight: isPast ? (data['historyHighlight'] as String? ?? 'Completed') : null,
      subdetail: (data['subdetail'] as String?) ?? (data['description'] as String?),
      voiceChannelUrl: data['voiceChannelUrl'] as String?,
    );
  }

  GameNightModel get upcomingGameNight {
    final next = upcomingSessions.firstOrNull;
    return next ??
        (_sessions.isNotEmpty ? allSessions.first : _placeholderSession);
  }

  GameNightModel get votingGameNight {
    final voting =
        _sessions.where((s) => s.status == GameNightStatus.voting).firstOrNull;
    return voting ??
        (_sessions.isNotEmpty ? _sessions.first : _placeholderSession);
  }

  GameNightModel? get pendingInvitation {
    final currentUid = _currentUserProfile?.id ?? 'p1';
    for (final s in _sessions) {
      final player = s.players.firstWhere(
        (p) =>
            p.id == currentUid ||
            p.id == 'p1' ||
            p.name.contains('(You)') ||
            p.name == 'You',
        orElse:
            () =>
                s.players.isNotEmpty
                    ? s.players.last
                    : const PlayerModel(
                      id: '',
                      name: '',
                      username: '@player',
                      avatarInitials: 'P',
                      avatarColorIndex: 0,
                    ),
      );
      if (player.rsvp == RSVPStatus.pending) return s;
    }
    return null;
  }

  List<GameNightModel> get recentGameNights => _sortedSessions(
    _sessions.where((s) {
      if (s.status == GameNightStatus.completed) return true;
      if (s.scheduledDateTime != null &&
          s.scheduledDateTime!.isBefore(DateTime.now().subtract(const Duration(hours: 4)))) {
        return true;
      }
      return false;
    }),
    descending: true,
  );

  List<GameNightModel> get upcomingSessions => _sortedSessions(
    _sessions.where(
      (s) {
        if (s.status == GameNightStatus.completed ||
            s.status == GameNightStatus.cancelled) {
          return false;
        }
        if (s.scheduledDateTime != null &&
            s.scheduledDateTime!.isBefore(DateTime.now().subtract(const Duration(hours: 4)))) {
          return false; // Already finished in the past!
        }
        return true;
      },
    ),
  );

  List<GameNightModel> get allSessions => _sortedSessions(_sessions);

  List<GameNightModel> _sortedSessions(
    Iterable<GameNightModel> source, {
    bool descending = false,
  }) {
    final sessions = source.toList();
    sessions.sort((a, b) {
      final aDate = a.scheduledDateTime;
      final bDate = b.scheduledDateTime;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      final comparison = aDate.compareTo(bDate);
      return descending ? -comparison : comparison;
    });
    return List.unmodifiable(sessions);
  }

  GameNightModel getSessionById(String id) {
    for (final s in _sessions) {
      if (s.id == id) return s;
    }
    return _sessions.isNotEmpty ? _sessions.first : _placeholderSession;
  }

  void _updateSession(
    String id,
    GameNightModel Function(GameNightModel) transform,
  ) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sessions[index] = transform(_sessions[index]);
      notifyListeners();
    }
  }

  // --- ACTIONS ON SESSIONS ---
  void castVote(String gameNightId, String gameId) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    _updateSession(gameNightId, (session) {
      final isAlreadyVoted = session.userVotedGameId == gameId;
      final updatedGames =
          session.votingGames.map((g) {
            if (g.id == gameId) {
              final newVotes =
                  isAlreadyVoted
                      ? (g.votes > 0 ? g.votes - 1 : 0)
                      : g.votes + 1;
              return g.copyWith(votes: newVotes);
            } else if (g.id == session.userVotedGameId) {
              return g.copyWith(votes: g.votes > 0 ? g.votes - 1 : 0);
            }
            return g;
          }).toList();

      final newVote = isAlreadyVoted ? null : gameId;
      return session.copyWith(
        votingGames: updatedGames,
        userVotedGameId: newVote,
      );
    });

    final target = getSessionById(gameNightId);
    final gameIndex = target.votingGames.indexWhere((g) => g.id == gameId);
    if (gameIndex != -1) {
      FirebaseService().castVote(
        gameNightId: gameNightId,
        gameIndex: gameIndex,
      );
    }
  }

  /// Lock voting and transition to planning with the top-voted game
  void lockVoting(String gameNightId) {
    GameModel? winner;
    _updateSession(gameNightId, (session) {
      if (session.votingGames.isNotEmpty) {
        winner = session.votingGames.first;
        for (final g in session.votingGames) {
          if (g.votes > (winner?.votes ?? -1)) {
            winner = g;
          }
        }
      }
      return session.copyWith(
        status: GameNightStatus.planning,
        selectedGame: winner,
      );
    });

    FirebaseService().updateGameNightStatus(
      gameNightId: gameNightId,
      status: 'planning',
      selectedGame:
          winner != null
              ? {
                'id': winner!.id,
                'title': winner!.title,
                'genre': winner!.genre,
                'emoji': winner!.emoji,
                'bannerGradientStart': winner!.bannerGradientStart,
                'bannerGradientEnd': winner!.bannerGradientEnd,
              }
              : null,
    );
  }

  /// Mark planning as ready
  void markSessionReady(String gameNightId) {
    _updateSession(gameNightId, (session) {
      return session.copyWith(status: GameNightStatus.ready);
    });
    FirebaseService().updateGameNightStatus(
      gameNightId: gameNightId,
      status: 'ready',
    );
  }

  /// Cancel a session
  void cancelSession(String gameNightId) {
    _updateSession(gameNightId, (session) {
      return session.copyWith(status: GameNightStatus.cancelled);
    });
    NotificationService().cancelSessionReminders(gameNightId);
    FirebaseService().updateGameNightStatus(
      gameNightId: gameNightId,
      status: 'cancelled',
    );
  }

  /// Mark session as completed (locks down mutations and transforms to Match Recap)
  void markSessionCompleted(String gameNightId) {
    _updateSession(gameNightId, (session) {
      return session.copyWith(status: GameNightStatus.completed);
    });
    NotificationService().cancelSessionReminders(gameNightId);
    FirebaseService().updateGameNightStatus(
      gameNightId: gameNightId,
      status: 'completed',
    );
  }

  /// Nominates a game (e.g., from Steam library) into the active voting session,
  /// ensuring it is also added to the DUWA games catalog.
  Future<bool> nominateGameForVoting(GameModel game) async {
    // 1. Ensure game is added to the catalog so squad can see and play it
    await addGameToCatalog(game);

    final votingIndex = _sessions.indexWhere(
      (s) => s.status == GameNightStatus.voting,
    );
    if (votingIndex == -1) {
      return false;
    }
    final session = _sessions[votingIndex];
    final exists = session.votingGames.any(
      (g) =>
          g.title.toLowerCase() == game.title.toLowerCase() ||
          g.id == game.id ||
          (game.steamAppId != null &&
              game.steamAppId! > 0 &&
              g.steamAppId == game.steamAppId),
    );
    if (exists) {
      return false;
    }

    final avatar = _currentUserProfile?.avatarInitials ?? 'U';
    final nominated = game.copyWith(votes: 1, voterAvatars: [avatar]);

    final updated = List<GameModel>.from(session.votingGames)..add(nominated);
    _sessions[votingIndex] = session.copyWith(
      votingGames: updated,
      userVotedGameId: nominated.id,
    );
    notifyListeners();

    try {
      final nominatedMaps = updated.map((g) => g.toMap()).toList();
      await FirebaseService().updateNominatedGames(
        gameNightId: session.id,
        nominatedGames: nominatedMaps,
      );
    } catch (e) {
      debugPrint('Firestore updateNominatedGames note: $e');
    }

    return true;
  }

  void toggleChecklistItem(String gameNightId, String itemId) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    List<ChecklistItemModel>? updatedList;
    _updateSession(gameNightId, (session) {
      updatedList =
          session.checklist.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isDone: !item.isDone);
            }
            return item;
          }).toList();
      return session.copyWith(checklist: updatedList!);
    });

    if (updatedList != null) {
      FirebaseService().updateGameNightChecklist(
        gameNightId: gameNightId,
        checklist:
            updatedList!
                .map(
                  (i) => {
                    'id': i.id,
                    'title': i.title,
                    'isDone': i.isDone,
                    'assignedTo': i.assignedTo,
                  },
                )
                .toList(),
      );
    }
  }

  void addChecklistItem(String gameNightId, ChecklistItemModel item) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    List<ChecklistItemModel>? updatedList;
    _updateSession(gameNightId, (session) {
      updatedList = List<ChecklistItemModel>.from(session.checklist)..add(item);
      return session.copyWith(checklist: updatedList!);
    });

    if (updatedList != null) {
      FirebaseService().updateGameNightChecklist(
        gameNightId: gameNightId,
        checklist:
            updatedList!
                .map(
                  (i) => {
                    'id': i.id,
                    'title': i.title,
                    'isDone': i.isDone,
                    'assignedTo': i.assignedTo,
                  },
                )
                .toList(),
      );
    }
  }

  /// Update editable details of a session (title, date/time, host note, voice channel, location)
  void updateSessionDetails(
    String gameNightId, {
    String? title,
    String? description,
    DateTime? scheduledDateTime,
    String? formattedTime,
    String? voiceChannelUrl,
    String? locationName,
  }) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    _updateSession(gameNightId, (session) {
      String? newFormattedDate = session.formattedDate;
      if (scheduledDateTime != null) {
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final now = DateTime.now();
        if (scheduledDateTime.year == now.year &&
            scheduledDateTime.month == now.month &&
            scheduledDateTime.day == now.day) {
          newFormattedDate = 'Tonight';
        } else {
          newFormattedDate =
              '${weekdays[scheduledDateTime.weekday - 1]}, ${months[scheduledDateTime.month - 1]} ${scheduledDateTime.day}';
        }
      }

      LocationPrepModel? newLocation = session.location;
      if (locationName != null && locationName.trim().isNotEmpty) {
        newLocation = LocationPrepModel(
          name: locationName.trim(),
          detail: session.location?.detail,
          isConfirmed: true,
        );
      }

      return session.copyWith(
        title: title?.trim().isNotEmpty == true ? title!.trim() : session.title,
        subdetail: description?.trim().isNotEmpty == true
            ? description!.trim()
            : session.subdetail,
        scheduledDateTime: scheduledDateTime ?? session.scheduledDateTime,
        formattedDate: newFormattedDate,
        formattedTime: formattedTime ?? session.formattedTime,
        voiceChannelUrl: voiceChannelUrl ?? session.voiceChannelUrl,
        location: newLocation,
      );
    });

    FirebaseService().updateSessionDetails(
      gameNightId: gameNightId,
      title: title?.trim(),
      description: description?.trim(),
      date: scheduledDateTime,
      time: formattedTime,
      voiceChannelUrl: voiceChannelUrl?.trim(),
      locationName: locationName?.trim(),
    );
  }

  void updatePlayerRSVP(
    String gameNightId,
    String playerId,
    RSVPStatus status,
  ) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    _updateSession(gameNightId, (session) {
      bool found = false;
      final updatedPlayers =
          session.players.map((p) {
            final isLegacyCurrentUser =
                _currentUserProfile != null &&
                p.name.replaceAll(' (You)', '').trim().toLowerCase() ==
                    _currentUserProfile!.displayName.trim().toLowerCase();
            final matchesUid = playerId.isNotEmpty && playerId != 'p1' && p.id == playerId;
            final matchesP1 = (playerId.isEmpty || playerId == 'p1') &&
                (p.id == 'p1' || p.name == 'You' || p.name.contains('(You)'));
            if (matchesUid || matchesP1 || isLegacyCurrentUser) {
              found = true;
              return p.copyWith(
                id: playerId.isNotEmpty ? playerId : p.id,
                rsvp: status,
              );
            }
            return p;
          }).toList();

      if (!found) {
        final myName = _currentUserProfile?.displayName ?? 'You';
        final myInitials = myName.isNotEmpty ? myName[0].toUpperCase() : 'U';
        updatedPlayers.add(
          PlayerModel(
            id: playerId.isNotEmpty ? playerId : 'p1',
            name: myName,
            username: '@${myName.toLowerCase().replaceAll(' ', '_')}',
            avatarInitials: myInitials,
            avatarColorIndex: 0,
            rsvp: status,
          ),
        );
      }
      return session.copyWith(players: updatedPlayers);
    });

    FirebaseService().updatePlayerRsvp(
      gameNightId: gameNightId,
      playerName: _currentUserProfile?.displayName ?? 'You',
      rsvp: status.name,
      uid: playerId,
    );
  }

  /// Respond to an invitation (I'm Going / Maybe / Can't Go)
  void respondToInvitation(String gameNightId, RSVPStatus status) {
    final currentUid = _currentUserProfile?.id ?? 'p1';
    updatePlayerRSVP(gameNightId, currentUid, status);
  }

  /// Participant claims or unclaims a preparation checklist item ("I'll bring this")
  void claimChecklistItem(String gameNightId, String itemId) {
    final cur = getSessionById(gameNightId);
    if (cur.status == GameNightStatus.completed ||
        cur.status == GameNightStatus.cancelled) {
      return;
    }
    final myName = _currentUserProfile?.displayName ?? 'You';
    List<ChecklistItemModel>? updatedList;
    _updateSession(gameNightId, (session) {
      updatedList =
          session.checklist.map((item) {
            if (item.id == itemId) {
              final isMine =
                  item.assignedTo == 'You' || item.assignedTo == myName;
              return item.copyWith(assignedTo: isMine ? null : myName);
            }
            return item;
          }).toList();
      return session.copyWith(checklist: updatedList!);
    });

    if (updatedList != null) {
      FirebaseService().updateGameNightChecklist(
        gameNightId: gameNightId,
        checklist:
            updatedList!
                .map(
                  (i) => {
                    'id': i.id,
                    'title': i.title,
                    'isDone': i.isDone,
                    'assignedTo': i.assignedTo,
                  },
                )
                .toList(),
      );
    }
  }

  // ==========================================
  // --- LINEAR PLANNING FLOW (FOOD ORDERING) ---
  // ==========================================
  int _currentCreationStep = 0;
  int get currentCreationStep => _currentCreationStep;

  GamerGroupModel? _draftGroup;
  GamerGroupModel? get draftGroup => _draftGroup;

  DateTime _draftDate = DateTime.now().add(const Duration(days: 1));
  DateTime get draftDate => _draftDate;

  String _draftTimeDisplay = '8:00 PM';
  String get draftTimeDisplay => _draftTimeDisplay;

  final List<GameModel> _draftSelectedGames = [];
  List<GameModel> get draftSelectedGames =>
      List.unmodifiable(_draftSelectedGames);
  GameNightModel? _lastCreatedSession;
  GameNightModel? get lastCreatedSession => _lastCreatedSession;

  List<PlayerModel> _draftPlayers = [];
  List<PlayerModel> get draftPlayers => _draftPlayers;

  String _draftFoodTitle = '';
  String get draftFoodTitle => _draftFoodTitle;

  String? _draftFoodBuyer;
  String? get draftFoodBuyer => _draftFoodBuyer;

  final List<String> _draftDrinks = [];
  List<String> get draftDrinks => List.unmodifiable(_draftDrinks);

  String _draftLocation = '';
  String get draftLocation => _draftLocation;

  List<ChecklistItemModel> _draftChecklist = [];
  List<ChecklistItemModel> get draftChecklist => _draftChecklist;
  String _draftTitle = '';
  String get draftTitle => _draftTitle;

  void setDraftTitle(String title) {
    _draftTitle = title;
    notifyListeners();
  }

  void startCreationFlow(
    GamerGroupModel? initialGroup, {
    GameModel? initialGame,
  }) {
    _currentCreationStep = 0;
    _draftTitle = '';
    _draftGroup = initialGroup;
    _draftDate = DateTime.now().add(const Duration(days: 2));
    _draftTimeDisplay = '8:00 PM';
    _draftSelectedGames.clear();
    if (initialGame != null) {
      _draftSelectedGames.add(initialGame);
    } else if (_catalogGames.isNotEmpty) {
      _draftSelectedGames.add(_catalogGames.first);
    }
    final userPlayer =
        _currentUserProfile != null
            ? PlayerModel(
              id: _currentUserProfile!.id,
              name: '${_currentUserProfile!.displayName} (You)',
              username: _currentUserProfile!.handle,
              avatarInitials: _currentUserProfile!.avatarInitials,
              avatarEmoji: _currentUserProfile!.avatarEmoji,
              avatarColorIndex: 0,
              rsvp: RSVPStatus.going,
            )
            : const PlayerModel(
              id: 'p1',
              name: 'You',
              username: '@you',
              avatarInitials: 'U',
              avatarEmoji: '🎮',
              avatarColorIndex: 0,
              rsvp: RSVPStatus.going,
            );

    if (_draftGroup != null) {
      _draftPlayers =
          _draftGroup!.members.map((p) {
            if (p.name.contains('(You)') ||
                p.id == 'p1' ||
                p.id == userPlayer.id) {
              return userPlayer;
            }
            return p;
          }).toList();
      if (!_draftPlayers.any((p) => p.id == userPlayer.id)) {
        _draftPlayers.insert(0, userPlayer);
      }
    } else {
      _draftPlayers = [userPlayer];
    }
    _draftFoodTitle = '';
    _draftFoodBuyer = null;
    _draftDrinks.clear();
    _draftLocation = '';
    _draftChecklist = [];
    notifyListeners();
  }

  void setCreationStep(int step) {
    _currentCreationStep = step;
    notifyListeners();
  }

  void nextCreationStep() {
    if (_currentCreationStep < 3) {
      _currentCreationStep++;
      notifyListeners();
    }
  }

  void prevCreationStep() {
    if (_currentCreationStep > 0) {
      _currentCreationStep--;
      notifyListeners();
    }
  }

  void selectDraftGroup(GamerGroupModel group) {
    _draftGroup = group;
    _draftPlayers = List<PlayerModel>.from(group.members);
    notifyListeners();
  }

  void setDraftDateTime(DateTime date, String timeDisplay) {
    _draftDate = date;
    _draftTimeDisplay = timeDisplay;
    notifyListeners();
  }

  bool get isDraftScheduleInFuture {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s(AM|PM)$',
    ).firstMatch(_draftTimeDisplay);
    if (match == null) return false;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (match.group(3) == 'PM' && hour != 12) hour += 12;
    if (match.group(3) == 'AM' && hour == 12) hour = 0;

    final scheduled = DateTime(
      _draftDate.year,
      _draftDate.month,
      _draftDate.day,
      hour,
      minute,
    );
    return scheduled.isAfter(DateTime.now().add(const Duration(minutes: 5)));
  }

  void selectSingleDraftGame(GameModel game) {
    _draftSelectedGames.clear();
    _draftSelectedGames.add(game);
    notifyListeners();
  }

  void clearDraftGames() {
    _draftSelectedGames.clear();
    notifyListeners();
  }

  void toggleDraftGame(GameModel game) {
    if (_draftSelectedGames.any((g) => g.id == game.id)) {
      if (_draftSelectedGames.length > 1) {
        _draftSelectedGames.removeWhere((g) => g.id == game.id);
      }
    } else {
      _draftSelectedGames.add(game);
    }
    notifyListeners();
  }

  void toggleDraftPlayerRSVP(String playerId, RSVPStatus newStatus) {
    final index = _draftPlayers.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _draftPlayers[index] = _draftPlayers[index].copyWith(rsvp: newStatus);
      notifyListeners();
    }
  }

  void setDraftFood(String title, String? buyer) {
    _draftFoodTitle = title;
    _draftFoodBuyer = buyer;
    notifyListeners();
  }

  void toggleDraftDrink(String drink) {
    if (_draftDrinks.contains(drink)) {
      _draftDrinks.remove(drink);
    } else {
      _draftDrinks.add(drink);
    }
    notifyListeners();
  }

  void setDraftLocation(String location) {
    _draftLocation = location;
    notifyListeners();
  }

  void addDraftChecklistItem(String title) {
    if (title.trim().isEmpty) return;
    _draftChecklist.add(
      ChecklistItemModel(
        id: 'dc-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
      ),
    );
    notifyListeners();
  }

  void removeDraftChecklistItem(String id) {
    _draftChecklist.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void confirmGameNight() {
    final isVoting = _draftSelectedGames.length > 1;
    // Compute real formatted date from _draftDate instead of hardcoding
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final computedDate =
        '${days[_draftDate.weekday % 7]}, ${months[_draftDate.month - 1]} ${_draftDate.day}';
    final title =
        _draftTitle.trim().isNotEmpty
            ? _draftTitle.trim()
            : '${_draftGroup?.name ?? "Squad"} Session';
    final sessionId = FirebaseService().newGameNightId();
    final newSession = GameNightModel(
      id: sessionId,
      title: title,
      group:
          _draftGroup ??
          GamerGroupModel(
            id: FirebaseService().newSquadId(),
            name: 'Squad',
            tagline: 'Squad',
            iconEmoji: '🎮',
            members: List.from(_draftPlayers),
          ),
      organizerName: _currentUserProfile?.displayName ?? 'You',
      scheduledDateTime: _draftDate,
      formattedDate: computedDate,
      formattedTime: _draftTimeDisplay,
      status: isVoting ? GameNightStatus.voting : GameNightStatus.ready,
      selectedGame:
          isVoting
              ? null
              : (_draftSelectedGames.isNotEmpty
                  ? _draftSelectedGames.first
                  : null),
      votingGames:
          isVoting
              ? _draftSelectedGames
                  .map(
                    (game) => game.copyWith(votes: 0, voterAvatars: const []),
                  )
                  .toList()
              : const [],
      players: List.from(_draftPlayers),
      food:
          _draftFoodTitle.trim().isNotEmpty
              ? FoodPrepModel(
                title: _draftFoodTitle.trim(),
                buyerName: _draftFoodBuyer,
                isReady: true,
              )
              : null,
      drinks:
          _draftDrinks.isNotEmpty
              ? DrinkPrepModel(items: List.from(_draftDrinks), isReady: true)
              : null,
      location:
          _draftLocation.trim().isNotEmpty
              ? LocationPrepModel(
                name: _draftLocation.trim(),
                isConfirmed: true,
              )
              : null,
      checklist: List.from(_draftChecklist),
      isHost: true,
      createdBy: _currentUserProfile?.id ?? FirebaseService().currentUser?.uid,
      playerUids: (_currentUserProfile?.id != null && _currentUserProfile!.id != 'user-default')
          ? [_currentUserProfile!.id]
          : (FirebaseService().currentUser?.uid != null ? [FirebaseService().currentUser!.uid] : []),
    );

    _lastCreatedSession = newSession;
    _joinedSessionIds.add(sessionId);
    _sessions.insert(0, newSession);
    _currentCreationStep = 3; // step 3 = success screen
    notifyListeners();

    // Asynchronously sync with Firebase Cloud Firestore
    FirebaseService().createGameNight(
      id: sessionId,
      title: newSession.title,
      groupId: newSession.group.id,
      groupName: newSession.group.name,
      date: newSession.scheduledDateTime ?? _draftDate,
      time: newSession.formattedTime,
      nominatedGames:
          _draftSelectedGames
              .map(
                (g) => {
                  'id': g.id,
                  'title': g.title,
                  'emoji': g.emoji,
                  'genre': g.genre,
                  'bannerGradientStart': g.bannerGradientStart,
                  'bannerGradientEnd': g.bannerGradientEnd,
                  'votes': 0,
                },
              )
              .toList(),
      selectedGame:
          newSession.selectedGame != null
              ? {
                'id': newSession.selectedGame!.id,
                'title': newSession.selectedGame!.title,
                'emoji': newSession.selectedGame!.emoji,
                'genre': newSession.selectedGame!.genre,
                'bannerGradientStart':
                    newSession.selectedGame!.bannerGradientStart,
                'bannerGradientEnd': newSession.selectedGame!.bannerGradientEnd,
              }
              : null,
      playerNames: _draftPlayers.map((p) => p.name).toList(),
      location:
          newSession.location != null
              ? {
                'name': newSession.location!.name,
                'detail': newSession.location!.detail,
              }
              : null,
      food:
          newSession.food != null
              ? {
                'title': newSession.food!.title,
                'buyerName': newSession.food!.buyerName,
              }
              : null,
      drinks: newSession.drinks?.items ?? [],
      checklist:
          newSession.checklist
              .map(
                (c) => {
                  'id': c.id,
                  'title': c.title,
                  'isDone': c.isDone,
                  'assignedTo': c.assignedTo,
                },
              )
              .toList(),
      organizerName: newSession.organizerName,
      uid: newSession.createdBy,
    );
  }

  /// Join a game night by its 6-character room code and ensure it is added to active sessions
  Future<GameNightModel?> joinSessionByCode(String roomCode) async {
    final myName = _currentUserProfile?.displayName ?? 'Player';
    final currentUid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final data = await FirebaseService().joinGameNightByCode(
      roomCode: roomCode,
      playerName: myName,
      uid: currentUid,
    );
    if (data == null) return null;

    final docId = data['id'] as String;
    _joinedSessionIds.add(docId);
    final session = _mapFirestoreDocToSession(docId, data);
    final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex != -1) {
      _sessions[existingIndex] = session;
    } else {
      _sessions.insert(0, session);
    }
    notifyListeners();
    return session;
  }

  Future<void> deleteSession(String sessionId) async {
    _deletedSessionIds.add(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
    await FirebaseService().deleteGameNight(sessionId);
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    _gamesSubscription?.cancel();
    super.dispose();
  }
}
