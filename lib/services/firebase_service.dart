import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/game_model.dart';

/// Clean, modular Firebase Service for DUWA.
/// Handles instant guest sign-in, email/password registration,
/// 6-character room code lobby joins, and Cloud Firestore live sync.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _gameNightsCol =>
      _firestore.collection('game_nights');
  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _gamesCol =>
      _firestore.collection('games');

  /// Current authenticated user (safe when running in tests or offline)
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream of authentication state changes (safe when running in tests)
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // ==========================================
  // --- AUTHENTICATION ---
  // ==========================================

  /// 1-Tap frictionless guest login (no forms needed for friends to join)
  Future<UserCredential?> signInAnonymously({
    String? displayName,
    String avatarEmoji = '🎮',
  }) async {
    try {
      final credential = await _auth.signInAnonymously();
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await saveUserProfile(
          uid: credential.user?.uid,
          displayName: displayName.trim(),
          avatarEmoji: avatarEmoji,
        );
      }
      debugPrint('Signed in anonymously: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('Anonymous sign in error: $e');
      return null;
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Send a password reset email for an existing account.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Register with Email and Password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String avatarEmoji = '🎮',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await saveUserProfile(
      uid: credential.user?.uid,
      displayName: displayName.trim(),
      avatarEmoji: avatarEmoji,
    );
    return credential;
  }

  /// Sign in with Google / Gmail (Native Account Chooser on mobile, OAuth popup on web)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final credential = await _auth.signInWithPopup(googleProvider);
        if (credential.user != null) {
          final user = credential.user!;
          final displayName =
              user.displayName ?? (user.email?.split('@').first ?? 'Player');
          await saveUserProfile(
            uid: user.uid,
            displayName: displayName,
            avatarEmoji: '⚡',
          );
        }
        return credential;
      }

      // Mobile (Android / iOS)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User dismissed the Google account chooser
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final displayName =
            userCredential.user!.displayName ??
            (googleUser.displayName ??
                (userCredential.user!.email?.split('@').first ?? 'Player'));
        await saveUserProfile(
          uid: userCredential.user!.uid,
          displayName: displayName,
          avatarEmoji: '⚡',
        );
      }
      return userCredential;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Save or update player profile in Firestore (safe with timeout)
  Future<void> saveUserProfile({
    String? uid,
    required String displayName,
    String? avatarEmoji,
    String? steamId,
    String? handle,
    String? bio,
    String? photoUrl,
    List<String>? favoriteGames,
  }) async {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null) return;
    try {
      await _usersCol
          .doc(targetUid)
          .set({
            'displayName': displayName,
            'avatarEmoji': avatarEmoji ?? '🎮',
            'steamId': steamId,
            if (handle != null) 'handle': handle,
            if (bio != null) 'bio': bio,
            if (photoUrl != null) 'photoUrl': photoUrl,
            if (favoriteGames != null) 'favoriteGames': favoriteGames,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint(
        'Firestore saveUserProfile note (offline or permission check): $e',
      );
    }
  }

  /// Get player profile (safe with timeout)
  Future<Map<String, dynamic>?> getUserProfile([String? uid]) async {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null) return null;
    try {
      final doc = await _usersCol
          .doc(targetUid)
          .get()
          .timeout(const Duration(seconds: 3));
      return doc.data();
    } catch (e) {
      debugPrint(
        'Firestore getUserProfile note (offline or permission check): $e',
      );
      return null;
    }
  }

  // ==========================================
  // --- ROOM CODES & MULTIPLAYER LOBBY ---
  // ==========================================

  /// Generate an arcade-style 6-character room code (e.g. DUWA-79K2)
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random();
    final code =
        List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
    return 'DUWA-$code';
  }

  /// Generate a unique Firestore document ID for a game night
  String newGameNightId() {
    try {
      return _gameNightsCol.doc().id;
    } catch (_) {
      return 'gn-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Publish a newly planned game night to Firestore with unique room code and full logistics
  Future<String?> createGameNight({
    String? id,
    required String title,
    required String groupId,
    required String groupName,
    required DateTime date,
    required String time,
    required List<Map<String, dynamic>> nominatedGames,
    required List<String> playerNames,
    String? roomCode,
    String? status,
    Map<String, dynamic>? selectedGame,
    Map<String, dynamic>? location,
    Map<String, dynamic>? food,
    List<String>? drinks,
    List<Map<String, dynamic>>? checklist,
    String? organizerName,
  }) async {
    try {
      final code = roomCode ?? generateRoomCode();
      final docRef =
          id != null && id.isNotEmpty
              ? _gameNightsCol.doc(id)
              : _gameNightsCol.doc();
      await docRef.set({
        'title': title,
        'roomCode': code,
        'groupId': groupId,
        'groupName': groupName,
        'date': Timestamp.fromDate(date),
        'time': time,
        'status': status ?? (nominatedGames.length > 1 ? 'voting' : 'ready'),
        'nominatedGames': nominatedGames,
        'selectedGame': selectedGame,
        'players':
            playerNames.map((name) => {'name': name, 'rsvp': 'going'}).toList(),
        'location': location,
        'food': food,
        'drinks': drinks ?? [],
        'checklist': checklist ?? [],
        'organizerName': organizerName ?? (currentUser?.displayName ?? 'You'),
        'createdBy': currentUser?.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating game night on Firebase: $e');
      return null;
    }
  }

  /// Update the lifecycle status of a session (e.g. voting -> planning -> ready -> completed -> cancelled)
  Future<void> updateGameNightStatus({
    required String gameNightId,
    required String status,
    Map<String, dynamic>? selectedGame,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (selectedGame != null) {
        updateData['selectedGame'] = selectedGame;
      }
      await _gameNightsCol.doc(gameNightId).update(updateData);
    } catch (e) {
      debugPrint('Error updating game night status: $e');
    }
  }

  /// Update checklist items in Cloud Firestore
  Future<void> updateGameNightChecklist({
    required String gameNightId,
    required List<Map<String, dynamic>> checklist,
  }) async {
    try {
      await _gameNightsCol.doc(gameNightId).update({
        'checklist': checklist,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating checklist in Firestore: $e');
    }
  }

  /// Delete a game night session from Firestore
  Future<bool> deleteGameNight(String gameNightId) async {
    try {
      await _gameNightsCol.doc(gameNightId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting game night on Firebase: $e');
      return false;
    }
  }

  /// Join an active squad session by its 6-character room code
  Future<Map<String, dynamic>?> joinGameNightByCode({
    required String roomCode,
    required String playerName,
  }) async {
    try {
      final formattedCode = roomCode.toUpperCase().trim();
      final query =
          await _gameNightsCol
              .where('roomCode', isEqualTo: formattedCode)
              .limit(1)
              .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      final alreadyJoined = players.any((p) => p['name'] == playerName);
      if (!alreadyJoined) {
        players.add({'name': playerName, 'rsvp': 'going'});
        await doc.reference.update({'players': players});
      }
      return {'id': doc.id, ...data, 'players': players};
    } catch (e) {
      debugPrint('Error joining game night by code: $e');
      return null;
    }
  }

  /// Stream real-time game nights from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGameNights() {
    return _gameNightsCol.orderBy('createdAt', descending: true).snapshots();
  }

  /// Cast a vote in real-time
  Future<void> castVote({
    required String gameNightId,
    required int gameIndex,
  }) async {
    try {
      final doc = await _gameNightsCol.doc(gameNightId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final games = List<Map<String, dynamic>>.from(
        data['nominatedGames'] ?? [],
      );
      if (gameIndex >= 0 && gameIndex < games.length) {
        games[gameIndex]['votes'] = (games[gameIndex]['votes'] ?? 0) + 1;
        await _gameNightsCol.doc(gameNightId).update({'nominatedGames': games});
      }
    } catch (e) {
      debugPrint('Error casting vote on Firebase: $e');
    }
  }

  /// Update player RSVP status in Firebase
  Future<void> updatePlayerRsvp({
    required String gameNightId,
    required String playerName,
    required String rsvp,
  }) async {
    try {
      final doc = await _gameNightsCol.doc(gameNightId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      final index = players.indexWhere((p) => p['name'] == playerName);
      if (index != -1) {
        players[index]['rsvp'] = rsvp;
        await _gameNightsCol.doc(gameNightId).update({'players': players});
      }
    } catch (e) {
      debugPrint('Error updating player rsvp status: $e');
    }
  }

  // ==========================================
  // --- SQUADS / GROUPS (Cloud Firestore) ---
  // ==========================================

  /// Stream squads from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGroups() {
    return _groupsCol.snapshots();
  }

  /// Generate a unique Firestore document ID for a squad
  String newSquadId() {
    try {
      return _groupsCol.doc().id;
    } catch (_) {
      return 'group-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Save squad to Firestore
  Future<String?> createSquad({
    String? id,
    required String name,
    required String iconEmoji,
    required List<String> memberNames,
    required String recentGame,
    String? tagline,
  }) async {
    try {
      final docRef =
          id != null && id.isNotEmpty ? _groupsCol.doc(id) : _groupsCol.doc();
      final squadCode = 'SQ-${docRef.id.toUpperCase().replaceAll('-', '')}';
      await docRef.set({
        'name': name,
        'iconEmoji': iconEmoji,
        'memberNames': memberNames,
        'recentGame': recentGame,
        'tagline': tagline ?? '${memberNames.length} members',
        'squadCode': squadCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating squad: $e');
      return null;
    }
  }

  /// Join a squad by squad code or ID
  Future<Map<String, dynamic>?> joinSquadByCode({
    required String code,
    required String playerName,
  }) async {
    try {
      final formatted = code.trim();
      final upperFormatted = formatted.toUpperCase();

      // Search by squadCode or document id
      QuerySnapshot<Map<String, dynamic>> query =
          await _groupsCol
              .where('squadCode', isEqualTo: upperFormatted)
              .limit(1)
              .get();

      DocumentSnapshot<Map<String, dynamic>>? targetDoc;
      if (query.docs.isNotEmpty) {
        targetDoc = query.docs.first;
      } else {
        // Try direct document id
        final directDoc = await _groupsCol.doc(formatted.toLowerCase()).get();
        if (directDoc.exists) {
          targetDoc = directDoc;
        }
      }

      if (targetDoc == null || !targetDoc.exists) return null;

      final data = targetDoc.data()!;
      final members = List<String>.from(data['memberNames'] ?? []);
      if (!members.any((m) => m.toLowerCase() == playerName.toLowerCase())) {
        members.add(playerName);
        await targetDoc.reference.update({
          'memberNames': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {'id': targetDoc.id, ...data, 'memberNames': members};
    } catch (e) {
      debugPrint('Error joining squad by code: $e');
      return null;
    }
  }

  /// Delete a squad from Firestore
  Future<bool> deleteSquad(String squadId) async {
    try {
      await _groupsCol.doc(squadId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting squad from Firebase: $e');
      return false;
    }
  }

  /// Update members list in a squad
  Future<bool> updateSquadMembers(
    String squadId,
    List<String> memberNames,
  ) async {
    try {
      await _groupsCol.doc(squadId).update({
        'memberNames': memberNames,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating squad members on Firebase: $e');
      return false;
    }
  }

  // ==========================================
  // --- GAMES CATALOG (Cloud Firestore) ---
  // ==========================================

  /// Stream live games catalog from Firestore
  Stream<List<GameModel>> streamGames() {
    try {
      return _gamesCol.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => GameModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Error streaming games from Firestore: $e');
      return const Stream.empty();
    }
  }

  /// Fetch games one-time with safety timeout
  Future<List<GameModel>> fetchGames() async {
    try {
      final snapshot = await _gamesCol.get().timeout(
        const Duration(seconds: 4),
      );
      return snapshot.docs
          .map((doc) => GameModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Firestore fetchGames note (offline or test mode): $e');
      return [];
    }
  }

  /// Add a custom game (e.g. Ragnarok Online) to Firestore
  Future<GameModel?> addGame(GameModel game) async {
    try {
      final data = game.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = currentUser?.uid;

      final docRef = await _gamesCol
          .add(data)
          .timeout(const Duration(seconds: 4));
      return game.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error saving game to Firestore: $e');
      return null;
    }
  }

  /// Seed initial curated games into Firestore if collection is empty
  Future<void> seedInitialGamesIfEmpty(List<GameModel> initialGames) async {
    try {
      final snapshot = await _gamesCol
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final game in initialGames) {
          final doc = _gamesCol.doc(game.id);
          final data = game.toMap();
          data['createdAt'] = FieldValue.serverTimestamp();
          batch.set(doc, data);
        }
        await batch.commit();
        debugPrint('Seeded ${initialGames.length} initial games to Firestore.');
      }
    } catch (e) {
      debugPrint('Firestore seedInitialGames note (offline or test mode): $e');
    }
  }
}
