import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_service.dart';

class GroupsViewModel extends ChangeNotifier {
  List<GamerGroupModel> _groups = [];
  final Set<String> _deletedGroupIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _squadsSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastCloudDocs = [];

  List<GamerGroupModel> get groups => List.unmodifiable(_groups);

  GroupsViewModel({bool withFixtureData = false}) {
    if (withFixtureData) {
      _groups = _createFixtureGroups();
    }
    // Do NOT subscribe here — wait for syncCurrentUser() with a valid user profile.
  }

  factory GroupsViewModel.withFixtureData() => GroupsViewModel(withFixtureData: true);

  /// Reset squad state (called on account switch / logout).
  /// Cancels subscriptions but does NOT restart them — they restart only once
  /// syncCurrentUser() is called with a valid user profile.
  void reset({bool withFixtureData = false}) {
    _squadsSubscription?.cancel();
    _squadsSubscription = null;
    _lastCloudDocs = [];
    _deletedGroupIds.clear();
    _groups = withFixtureData ? _createFixtureGroups() : [];
    _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    _currentUserProfile = null;
    notifyListeners();
  }

  static List<GamerGroupModel> _createFixtureGroups() => [
        const GamerGroupModel(
          id: 'group-1',
          name: 'Weekend Squad',
          tagline: '5 members · Valorant & Chill',
          iconEmoji: '🎯',
          totalGameNights: 12,
          recentGame: 'Valorant',
          members: [
            PlayerModel(id: 'p1', name: 'You', username: '@you', avatarInitials: 'U', avatarEmoji: '🎮', avatarColorIndex: 0, rsvp: RSVPStatus.going),
            PlayerModel(id: 'p2', name: 'Alex', username: '@alex_k', avatarInitials: 'A', avatarColorIndex: 1, rsvp: RSVPStatus.going),
            PlayerModel(id: 'p3', name: 'Jordan', username: '@jordan_m', avatarInitials: 'J', avatarColorIndex: 2, rsvp: RSVPStatus.going),
            PlayerModel(id: 'p4', name: 'Sam', username: '@sam_t', avatarInitials: 'S', avatarColorIndex: 3, rsvp: RSVPStatus.maybe),
            PlayerModel(id: 'p5', name: 'Taylor', username: '@taylor_r', avatarInitials: 'T', avatarColorIndex: 4, rsvp: RSVPStatus.going),
          ],
        ),
      ];

  bool _isUserMemberOfSquad(Map<String, dynamic> data) {
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

    final memberUids = List<String>.from(data['memberUids'] ?? []);
    if (currentUid != null && currentUid != 'user-default' && memberUids.contains(currentUid)) {
      return true;
    }

    final memberNames = List<String>.from(data['memberNames'] ?? []);
    if (memberNames.isEmpty) return false;

    return memberNames.any((m) {
      final norm = m.replaceAll('(You)', '').trim().toLowerCase();
      if (currentName != null && currentName != 'player' && currentName != 'you' && norm == currentName) return true;
      if (_currentUserProfile?.handle != null) {
        final cleanHandle = _currentUserProfile!.handle.toLowerCase().replaceAll('@', '').trim();
        if (cleanHandle.isNotEmpty && cleanHandle != 'gamer' && cleanHandle != 'you' && norm == cleanHandle) return true;
      }
      return false;
    });
  }

  void _rebuildGroupsFromDocs() {
    if (_lastCloudDocs.isEmpty) return;

    final userSquadDocs = _lastCloudDocs.where((doc) => _isUserMemberOfSquad(doc.data())).toList();
    final cloudGroups = userSquadDocs.map((doc) {
      final data = doc.data();
      final memberNames = List<String>.from(data['memberNames'] ?? []);
      final members = memberNames.map((name) => PlayerModel(
        id: 'p-${name.hashCode}',
        name: name,
        username: '@${name.toLowerCase().replaceAll(' ', '_')}',
        avatarInitials: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
        avatarColorIndex: (name.hashCode % 6).abs(),
        rsvp: RSVPStatus.going,
      )).toList();

      return GamerGroupModel(
        id: doc.id,
        name: data['name'] ?? 'Squad',
        tagline: data['tagline'] ?? '${members.length} members',
        iconEmoji: data['iconEmoji'] ?? '🎮',
        recentGame: data['recentGame'] ?? 'Valorant',
        members: members,
        createdBy: data['createdBy'] as String?,
        memberUids: List<String>.from(data['memberUids'] ?? []),
      );
    }).toList();

    final filteredCloud = cloudGroups.where((g) => !_deletedGroupIds.contains(g.id)).toList();
    final cloudIds = filteredCloud.map((g) => g.id).toSet();

    final pendingLocals = _groups.where((g) => !cloudIds.contains(g.id) && !_deletedGroupIds.contains(g.id) && !g.id.startsWith('group-1')).toList();

    _groups = [...filteredCloud, ...pendingLocals];
    if (_selectedGroup != null && _deletedGroupIds.contains(_selectedGroup!.id)) {
      _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    } else if (_selectedGroup != null) {
      final match = _groups.where((g) => g.id == _selectedGroup!.id);
      if (match.isNotEmpty) {
        _selectedGroup = match.first;
      }
    }
  }

  void initFirebaseSquads() {
    // Guard: only subscribe to squad data when we have a valid authenticated user.
    final uid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    if (uid == null || uid == 'user-default') {
      debugPrint('initFirebaseSquads: no authenticated user — subscription skipped');
      return;
    }
    try {
      _squadsSubscription?.cancel();
      _squadsSubscription = FirebaseService().streamGroups(uid: uid).listen((snapshot) {
        _lastCloudDocs = snapshot.docs;
        _rebuildGroupsFromDocs();
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore squads stream error: $e');
      });
    } catch (e) {
      debugPrint('Firestore squads sync note (offline or test mode): $e');
    }
  }

  GamerGroupModel? _selectedGroup;
  GamerGroupModel? get selectedGroup => _selectedGroup ?? (_groups.isNotEmpty ? _groups.first : null);

  void selectGroup(GamerGroupModel group) {
    _selectedGroup = group;
    notifyListeners();
  }

  UserProfileModel? _currentUserProfile;

  void syncCurrentUser(UserProfileModel profile) {
    _currentUserProfile = profile;

    // If squad subscriptions were cancelled (e.g. after reset() on an account
    // switch) and we now have a valid authenticated user, restart them.
    if (_squadsSubscription == null && profile.id != 'user-default') {
      initFirebaseSquads();
      // Fall through — still update the "You" label on any locally-cached squads.
    } else {
      _rebuildGroupsFromDocs();
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

    for (int i = 0; i < _groups.length; i++) {
      final updatedMembers = _groups[i].members.map((p) {
        if (p.id == 'p1' || p.id == profile.id || p.name.contains('(You)') || p.name == 'You') {
          return userPlayer;
        }
        return p;
      }).toList();
      _groups[i] = _groups[i].copyWith(members: updatedMembers);
    }
    notifyListeners();
  }

  void addGroup({
    required String name,
    required String tagline,
    required String emoji,
  }) {
    final userPlayer = _currentUserProfile != null
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

    final currentUid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final squadId = FirebaseService().newSquadId();
    final newGroup = GamerGroupModel(
      id: squadId,
      name: name,
      tagline: tagline,
      iconEmoji: emoji,
      members: [userPlayer],
      createdBy: currentUid,
      memberUids: (currentUid != null && currentUid != 'user-default') ? [currentUid] : [],
    );
    _groups.insert(0, newGroup);
    _selectedGroup = newGroup;
    notifyListeners();

    FirebaseService().createSquad(
      id: squadId,
      name: name,
      iconEmoji: emoji,
      memberNames: newGroup.members.map((member) => member.name).toList(),
      recentGame: newGroup.recentGame,
      tagline: tagline,
      uid: currentUid,
    );
  }

  /// Join a squad by code or id and update local state
  Future<GamerGroupModel?> joinSquadByCode(String code) async {
    final myName = _currentUserProfile?.displayName ?? 'Player';
    final currentUid = _currentUserProfile?.id ?? FirebaseService().currentUser?.uid;
    final data = await FirebaseService().joinSquadByCode(
      code: code,
      playerName: myName,
      uid: currentUid,
    );
    if (data == null) return null;

    final memberNames = List<String>.from(data['memberNames'] ?? []);
    final members = memberNames.map((name) => PlayerModel(
      id: 'p-${name.hashCode}',
      name: name,
      username: '@${name.toLowerCase().replaceAll(' ', '_')}',
      avatarInitials: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
      avatarColorIndex: (name.hashCode % 6).abs(),
      rsvp: RSVPStatus.going,
    )).toList();

    final group = GamerGroupModel(
      id: data['id'] as String? ?? code,
      name: data['name'] ?? 'Squad',
      tagline: data['tagline'] ?? '${members.length} members',
      iconEmoji: data['iconEmoji'] ?? '🎮',
      recentGame: data['recentGame'] ?? 'Valorant',
      members: members,
      createdBy: data['createdBy'] as String?,
      memberUids: List<String>.from(data['memberUids'] ?? []),
    );

    final existingIndex = _groups.indexWhere((g) => g.id == group.id);
    if (existingIndex != -1) {
      _groups[existingIndex] = group;
    } else {
      _groups.insert(0, group);
    }
    _selectedGroup = group;
    notifyListeners();
    return group;
  }

  static const List<Map<String, String>> suggestedGamers = [
    {'name': 'Alex', 'tag': '@alex_k', 'emoji': '⚡'},
    {'name': 'Jordan', 'tag': '@jordan_m', 'emoji': '🔥'},
    {'name': 'Sam', 'tag': '@sam_t', 'emoji': '🎯'},
    {'name': 'Taylor', 'tag': '@taylor_r', 'emoji': '🎲'},
    {'name': 'Morgan', 'tag': '@morgan_x', 'emoji': '🦊'},
    {'name': 'Chris', 'tag': '@chris_gg', 'emoji': '👾'},
  ];

  Future<bool> addMemberToSquad({
    required String squadId,
    required String memberName,
    String? username,
    String? avatarEmoji,
  }) async {
    final trimmedName = memberName.trim();
    if (trimmedName.isEmpty) return false;

    final groupIndex = _groups.indexWhere((g) => g.id == squadId);
    if (groupIndex == -1) return false;

    final targetGroup = _groups[groupIndex];
    if (targetGroup.members.any((m) => m.name.toLowerCase() == trimmedName.toLowerCase())) {
      return false;
    }

    final newMember = PlayerModel(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      username: username ?? '@${trimmedName.toLowerCase().replaceAll(' ', '_')}',
      avatarInitials: trimmedName.isNotEmpty ? trimmedName.substring(0, 1).toUpperCase() : 'P',
      avatarEmoji: avatarEmoji ?? '🎮',
      avatarColorIndex: (trimmedName.hashCode % 6).abs(),
      rsvp: RSVPStatus.going,
    );

    final updatedMembers = [...targetGroup.members, newMember];
    final updatedGroup = targetGroup.copyWith(
      members: updatedMembers,
      tagline: '${updatedMembers.length} members',
    );

    _groups[groupIndex] = updatedGroup;
    if (_selectedGroup?.id == squadId) {
      _selectedGroup = updatedGroup;
    }
    notifyListeners();

    await FirebaseService().updateSquadMembers(
      squadId,
      updatedMembers.map((m) => m.name).toList(),
    );
    return true;
  }

  Future<void> removeMemberFromSquad(String squadId, String memberId) async {
    final groupIndex = _groups.indexWhere((g) => g.id == squadId);
    if (groupIndex == -1) return;

    final targetGroup = _groups[groupIndex];
    final updatedMembers = targetGroup.members.where((m) => m.id != memberId).toList();
    final updatedGroup = targetGroup.copyWith(
      members: updatedMembers,
      tagline: '${updatedMembers.length} members',
    );

    _groups[groupIndex] = updatedGroup;
    if (_selectedGroup?.id == squadId) {
      _selectedGroup = updatedGroup;
    }
    notifyListeners();

    await FirebaseService().updateSquadMembers(
      squadId,
      updatedMembers.map((m) => m.name).toList(),
    );
  }

  Future<void> deleteSquad(String squadId) async {
    _deletedGroupIds.add(squadId);
    _groups.removeWhere((g) => g.id == squadId);
    if (_selectedGroup?.id == squadId) {
      _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    }
    notifyListeners();
    await FirebaseService().deleteSquad(squadId);
  }

  @override
  void dispose() {
    _squadsSubscription?.cancel();
    super.dispose();
  }
}
