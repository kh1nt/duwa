import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/game_model.dart';
import 'preferences_service.dart';

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

  static const String _googleServerClientId =
      '334046732760-m378ogsgeqa8j2202hgrpv4a3q5bv388.apps.googleusercontent.com';

  GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      serverClientId: _googleServerClientId,
      scopes: const ['email', 'profile'],
    );
  }

  /// Sign in with Google / Gmail (Native Account Chooser on mobile, OAuth popup on web, provider on desktop)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final isDesktop = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux);

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

      if (isDesktop) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final credential = await _auth.signInWithProvider(googleProvider);
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
      final GoogleSignIn googleSignIn = _buildGoogleSignIn();
      // Explicitly sign out of any cached Google session before calling signIn,
      // guaranteeing that the native Google Account Chooser dialog is always presented.
      try {
        await googleSignIn.signOut();
      } catch (_) {}

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

  /// Sign out from Firebase Auth, Google SSO, and clear local session state
  Future<void> signOut() async {
    try {
      await PreferencesService().clearUserSessionData();
    } catch (_) {}
    try {
      final googleSignIn = _buildGoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut note: $e');
    }
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

  /// Look up real registered users in Firestore by handle or displayName
  Future<List<Map<String, dynamic>>> searchRegisteredUsers(String query) async {
    final cleanQuery = query.trim().replaceAll('@', '').toLowerCase();
    if (cleanQuery.isEmpty) return [];

    try {
      final snapshot = await _usersCol.limit(30).get().timeout(const Duration(seconds: 4));
      final results = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final displayName = (data['displayName'] as String? ?? '').toLowerCase();
        final handle = (data['handle'] as String? ?? '').replaceAll('@', '').toLowerCase();
        if (displayName.contains(cleanQuery) || handle.contains(cleanQuery)) {
          results.add({'uid': doc.id, ...data});
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error searching registered users: $e');
      return [];
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
    String? uid,
  }) async {
    try {
      final code = roomCode ?? generateRoomCode();
      final docRef =
          id != null && id.isNotEmpty
              ? _gameNightsCol.doc(id)
              : _gameNightsCol.doc();
      final creatorUid = uid ?? currentUser?.uid;
      final playerUids = <String>[];
      if (creatorUid != null && creatorUid.isNotEmpty && creatorUid != 'guest') {
        playerUids.add(creatorUid);
      }
      final playersList = <Map<String, dynamic>>[];
      for (int i = 0; i < playerNames.length; i++) {
        final name = playerNames[i];
        final cleanName = name.replaceAll(' (You)', '').replaceAll('(You)', '').trim();
        final isCreator = i == 0 || (creatorUid != null && name.contains('(You)'));
        playersList.add({
          'id': isCreator && creatorUid != null ? creatorUid : 'p-${name.hashCode}',
          'name': cleanName.isNotEmpty ? cleanName : 'Player',
          'rsvp': 'going',
        });
      }

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
        'players': playersList,
        'playerUids': playerUids,
        'location': location,
        'food': food,
        'drinks': drinks ?? [],
        'checklist': checklist ?? [],
        'organizerName': organizerName ?? (currentUser?.displayName ?? 'Host'),
        'createdBy': creatorUid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating game night on Firebase: $e');
      return null;
    }
  }

  /// Update the lifecycle status of a session (e.g. voting -> planning -> ready -> completed -> cancelled)
  Future<bool> updateGameNightStatus({
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
      await _gameNightsCol
          .doc(gameNightId)
          .update(updateData)
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Error updating game night status: $e');
      return false;
    }
  }

  /// Update checklist items in Cloud Firestore
  Future<bool> updateGameNightChecklist({
    required String gameNightId,
    required List<Map<String, dynamic>> checklist,
  }) async {
    try {
      await _gameNightsCol.doc(gameNightId).update({
        'checklist': checklist,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Error updating checklist in Firestore: $e');
      return false;
    }
  }

  /// Update editable details of a game night session in Firestore
  Future<bool> updateSessionDetails({
    required String gameNightId,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? voiceChannelUrl,
    String? locationName,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) updates['title'] = title;
      if (description != null) {
        updates['description'] = description;
        updates['subdetail'] = description;
      }
      if (date != null) updates['date'] = Timestamp.fromDate(date);
      if (time != null) updates['time'] = time;
      if (voiceChannelUrl != null) updates['voiceChannelUrl'] = voiceChannelUrl;
      if (locationName != null) {
        updates['location'] = {'name': locationName, 'isConfirmed': true};
      }
      await _gameNightsCol
          .doc(gameNightId)
          .update(updates)
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Error updating session details on Firebase: $e');
      return false;
    }
  }

  /// Append a new bring-list item to an active session
  Future<bool> addChecklistItemToSession({
    required String gameNightId,
    required Map<String, dynamic> item,
  }) async {
    try {
      await _gameNightsCol.doc(gameNightId).update({
        'checklist': FieldValue.arrayUnion([item]),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Error adding checklist item to Firebase: $e');
      return false;
    }
  }

  /// Delete a game night session from Firestore
  Future<bool> deleteGameNight(String gameNightId) async {
    try {
      await _gameNightsCol
          .doc(gameNightId)
          .delete()
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Error deleting game night on Firebase: $e');
      return false;
    }
  }

  /// Join an active squad session by room code (supports DUWA-XXXX, DW-XXXX, or 4-char suffix)
  Future<Map<String, dynamic>?> joinGameNightByCode({
    required String roomCode,
    required String playerName,
    String? uid,
  }) async {
    try {
      final formatted = roomCode.toUpperCase().trim();
      final withoutPrefix = formatted.startsWith('DUWA-')
          ? formatted.substring(5)
          : (formatted.startsWith('DW-') ? formatted.substring(3) : formatted);
      final duwaVariant = 'DUWA-$withoutPrefix';
      final dwVariant = 'DW-$withoutPrefix';

      final query = await _gameNightsCol
          .where('roomCode', whereIn: [formatted, duwaVariant, dwVariant, withoutPrefix])
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isEmpty) {
        // Check by document ID as fallback
        final directDoc = await _gameNightsCol
            .doc(roomCode.trim().toLowerCase())
            .get()
            .timeout(const Duration(seconds: 8));
        if (!directDoc.exists) return null;
        return {'id': directDoc.id, ...directDoc.data()!};
      }

      final doc = query.docs.first;
      final data = doc.data();
      final currentUid = uid ?? currentUser?.uid;
      final cleanName = playerName.replaceAll(' (You)', '').replaceAll('(You)', '').trim();
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      final alreadyJoined = players.any(
        (p) => (currentUid != null && currentUid.isNotEmpty && p['id'] == currentUid) || p['name'] == cleanName,
      );
      final updates = <String, dynamic>{};
      if (!alreadyJoined) {
        players.add({
          'id': currentUid ?? 'p-${DateTime.now().millisecondsSinceEpoch}',
          'name': cleanName.isNotEmpty ? cleanName : 'Player',
          'rsvp': 'going',
        });
        updates['players'] = players;
      }
      if (currentUid != null && currentUid.isNotEmpty && currentUid != 'guest') {
        final existingUids = List<String>.from(data['playerUids'] ?? []);
        if (!existingUids.contains(currentUid)) {
          updates['playerUids'] = FieldValue.arrayUnion([currentUid]);
        }
      }
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(updates).timeout(const Duration(seconds: 8));
      }
      return {'id': doc.id, ...data, 'players': players};
    } catch (e) {
      debugPrint('Error joining game night by code: $e');
      return null;
    }
  }

  /// Stream real-time game nights from Firestore for the given user.
  /// Scopes queries to documents containing the user's UID in [playerUids].
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGameNights({String? uid}) {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null || targetUid == 'user-default' || targetUid.isEmpty) {
      return const Stream.empty();
    }
    try {
      return _gameNightsCol
          .where('playerUids', arrayContains: targetUid)
          .snapshots();
    } catch (e) {
      debugPrint('Error streaming game nights: $e');
      return const Stream.empty();
    }
  }

  /// Cast a vote in real-time using atomic Firestore transaction
  /// to eliminate race conditions when squad members vote simultaneously.
  Future<bool> castVote({
    required String gameNightId,
    required int gameIndex,
  }) async {
    try {
      final docRef = _gameNightsCol.doc(gameNightId);
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) return false;

        final data = snapshot.data()!;
        final games = List<Map<String, dynamic>>.from(
          data['nominatedGames'] ?? [],
        );
        if (gameIndex >= 0 && gameIndex < games.length) {
          games[gameIndex] = Map<String, dynamic>.from(games[gameIndex]);
          games[gameIndex]['votes'] = (games[gameIndex]['votes'] ?? 0) + 1;
          transaction.update(docRef, {
            'nominatedGames': games,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
        return false;
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Firestore castVote transaction note: $e');
      return false;
    }
  }

  /// Update nominated games for a session in Firestore
  Future<bool> updateNominatedGames({
    required String gameNightId,
    required List<Map<String, dynamic>> nominatedGames,
  }) async {
    try {
      await _gameNightsCol.doc(gameNightId).update({
        'nominatedGames': nominatedGames,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('Firestore updateNominatedGames note: $e');
      return false;
    }
  }

  /// Update player RSVP status in Firebase using atomic Firestore transaction
  /// to prevent concurrent RSVP updates from clobbering other players' status.
  Future<bool> updatePlayerRsvp({
    required String gameNightId,
    required String playerName,
    required String rsvp,
    String? uid,
  }) async {
    try {
      final docRef = _gameNightsCol.doc(gameNightId);
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) return false;

        final data = snapshot.data()!;
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final index = players.indexWhere((p) =>
            (uid != null && uid.isNotEmpty && p['id'] == uid) ||
            p['name'] == playerName);
        if (index != -1) {
          players[index] = Map<String, dynamic>.from(players[index]);
          if (uid != null && uid.isNotEmpty) {
            players[index]['id'] = uid;
          }
          players[index]['rsvp'] = rsvp;
        } else {
          players.add({
            if (uid != null && uid.isNotEmpty) 'id': uid,
            'name': playerName,
            'rsvp': rsvp,
          });
        }
        transaction.update(docRef, {
          'players': players,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Firestore updatePlayerRsvp transaction note: $e');
      return false;
    }
  }

  // ==========================================
  // --- SQUADS / GROUPS (Cloud Firestore) ---
  // ==========================================

  /// Stream squads from Firestore for the given user.
  /// Scopes queries to documents containing the user's UID in [memberUids].
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGroups({String? uid}) {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null || targetUid == 'user-default' || targetUid.isEmpty) {
      return const Stream.empty();
    }
    try {
      return _groupsCol
          .where('memberUids', arrayContains: targetUid)
          .snapshots();
    } catch (e) {
      debugPrint('Error streaming groups: $e');
      return const Stream.empty();
    }
  }

  /// Generate a unique Firestore document ID for a squad
  String newSquadId() {
    try {
      return _groupsCol.doc().id;
    } catch (_) {
      return 'group-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Generate a concise arcade-style 6-character squad code (e.g. SQ-79K2)
  String generateSquadCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random();
    final code =
        List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
    return 'SQ-$code';
  }

  /// Save squad to Firestore
  Future<String?> createSquad({
    String? id,
    required String name,
    required String iconEmoji,
    required List<String> memberNames,
    required String recentGame,
    String? tagline,
    String? uid,
    String? squadCode,
  }) async {
    try {
      final docRef =
          id != null && id.isNotEmpty ? _groupsCol.doc(id) : _groupsCol.doc();
      final code = squadCode ?? generateSquadCode();
      final creatorUid = uid ?? currentUser?.uid;
      final memberUids = <String>[];
      if (creatorUid != null && creatorUid.isNotEmpty && creatorUid != 'guest') {
        memberUids.add(creatorUid);
      }
      final cleanMemberNames = memberNames
          .map((m) => m.replaceAll(' (You)', '').replaceAll('(You)', '').trim())
          .where((m) => m.isNotEmpty)
          .toList();

      await docRef.set({
        'name': name,
        'iconEmoji': iconEmoji,
        'memberNames': cleanMemberNames,
        'memberUids': memberUids,
        'recentGame': recentGame,
        'tagline': tagline ?? '${cleanMemberNames.length} members',
        'squadCode': code,
        'createdBy': creatorUid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating squad: $e');
      return null;
    }
  }

  /// Join a squad by squad code (SQ-XXXX or XXXX) or document ID
  Future<Map<String, dynamic>?> joinSquadByCode({
    required String code,
    required String playerName,
    String? uid,
  }) async {
    try {
      final formatted = code.trim();
      final upperFormatted = formatted.toUpperCase();
      final withoutPrefix = upperFormatted.startsWith('SQ-')
          ? upperFormatted.substring(3)
          : upperFormatted;
      final withPrefix = 'SQ-$withoutPrefix';

      // Search by squadCode variations
      QuerySnapshot<Map<String, dynamic>> query =
          await _groupsCol
              .where('squadCode', whereIn: [upperFormatted, withPrefix, withoutPrefix])
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));

      DocumentSnapshot<Map<String, dynamic>>? targetDoc;
      if (query.docs.isNotEmpty) {
        targetDoc = query.docs.first;
      } else {
        // Try direct document id
        final directDoc = await _groupsCol
            .doc(formatted.toLowerCase())
            .get()
            .timeout(const Duration(seconds: 8));
        if (directDoc.exists) {
          targetDoc = directDoc;
        } else {
          final directUpper = await _groupsCol
              .doc(upperFormatted)
              .get()
              .timeout(const Duration(seconds: 8));
          if (directUpper.exists) {
            targetDoc = directUpper;
          }
        }
      }

      if (targetDoc == null || !targetDoc.exists) return null;

      final data = targetDoc.data()!;
      final currentUid = uid ?? currentUser?.uid;
      final cleanName = playerName.replaceAll(' (You)', '').replaceAll('(You)', '').trim();
      final members = List<String>.from(data['memberNames'] ?? []);
      final updates = <String, dynamic>{};

      if (!members.any((m) => m.toLowerCase() == cleanName.toLowerCase())) {
        members.add(cleanName);
        updates['memberNames'] = members;
      }
      if (currentUid != null && currentUid.isNotEmpty && currentUid != 'guest') {
        final existingUids = List<String>.from(data['memberUids'] ?? []);
        if (!existingUids.contains(currentUid)) {
          updates['memberUids'] = FieldValue.arrayUnion([currentUid]);
        }
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await targetDoc.reference.update(updates).timeout(const Duration(seconds: 8));
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
      await _groupsCol
          .doc(squadId)
          .delete()
          .timeout(const Duration(seconds: 8));
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
      }).timeout(const Duration(seconds: 8));
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
