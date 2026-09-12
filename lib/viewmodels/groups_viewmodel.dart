import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_service.dart';

class GroupsViewModel extends ChangeNotifier {
  List<GamerGroupModel> _groups = [];
  final Set<String> _deletedGroupIds = {};

  List<GamerGroupModel> get groups => List.unmodifiable(_groups);

  GroupsViewModel({bool withFixtureData = false}) {
    if (withFixtureData) {
      _groups = _createFixtureGroups();
    }
    initFirebaseSquads();
  }

  factory GroupsViewModel.withFixtureData() => GroupsViewModel(withFixtureData: true);

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

  void initFirebaseSquads() {
    try {
      FirebaseService().streamGroups().listen((snapshot) {
        final cloudGroups = snapshot.docs.map((doc) {
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
          );
        }).toList();

        // Filter out any locally deleted squads
        final filteredCloud = cloudGroups.where((g) => !_deletedGroupIds.contains(g.id)).toList();
        final cloudIds = filteredCloud.map((g) => g.id).toSet();

        // Keep local groups that haven't hit the cloud yet and aren't deleted
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

    final squadId = FirebaseService().newSquadId();
    final newGroup = GamerGroupModel(
      id: squadId,
      name: name,
      tagline: tagline,
      iconEmoji: emoji,
      members: [userPlayer],
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
    );
  }

  /// Join a squad by code or id and update local state
  Future<GamerGroupModel?> joinSquadByCode(String code) async {
    final myName = _currentUserProfile?.displayName ?? 'You';
    final data = await FirebaseService().joinSquadByCode(
      code: code,
      playerName: myName,
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

    final squad = GamerGroupModel(
      id: data['id'] as String,
      name: data['name'] ?? 'Squad',
      tagline: data['tagline'] ?? '${members.length} members',
      iconEmoji: data['iconEmoji'] ?? '🎮',
      recentGame: data['recentGame'] ?? 'Valorant',
      members: members,
    );

    final existingIndex = _groups.indexWhere((g) => g.id == squad.id);
    if (existingIndex != -1) {
      _groups[existingIndex] = squad;
    } else {
      _groups.insert(0, squad);
    }
    _selectedGroup = squad;
    notifyListeners();
    return squad;
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
}
