enum RSVPStatus {
  going,
  maybe,
  cantGo,
  pending,
}

class PlayerModel {
  final String id;
  final String name;
  final String username;
  final String avatarInitials;
  final String? avatarEmoji;
  final int avatarColorIndex;
  final RSVPStatus rsvp;
  final bool isOnline;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarInitials,
    this.avatarEmoji,
    required this.avatarColorIndex,
    this.rsvp = RSVPStatus.pending,
    this.isOnline = true,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    String? username,
    String? avatarInitials,
    String? avatarEmoji,
    int? avatarColorIndex,
    RSVPStatus? rsvp,
    bool? isOnline,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      rsvp: rsvp ?? this.rsvp,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModel && runtimeType == other.runtimeType && id == other.id;

  bool get isHost => name == 'You' || name.contains('(You)');
  String get preferredRole => isHost ? 'Team Captain' : 'Squad Member';

  @override
  int get hashCode => id.hashCode;
}

class GamerGroupModel {
  final String id;
  final String name;
  final String tagline;
  final String iconEmoji;
  final List<PlayerModel> members;
  final int totalGameNights;
  final String recentGame;
  final String? createdBy;
  final List<String> memberUids;
  final String? squadCode;

  const GamerGroupModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.iconEmoji,
    required this.members,
    this.totalGameNights = 0,
    this.recentGame = 'Valorant',
    this.createdBy,
    this.memberUids = const [],
    this.squadCode,
  });

  int get memberCount => members.length;

  String get displaySquadCode => (squadCode != null && squadCode!.isNotEmpty)
      ? squadCode!
      : 'SQ-${id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase()}';

  GamerGroupModel copyWith({
    String? id,
    String? name,
    String? tagline,
    String? iconEmoji,
    List<PlayerModel>? members,
    int? totalGameNights,
    String? recentGame,
    String? createdBy,
    List<String>? memberUids,
    String? squadCode,
  }) {
    return GamerGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      members: members ?? this.members,
      totalGameNights: totalGameNights ?? this.totalGameNights,
      recentGame: recentGame ?? this.recentGame,
      createdBy: createdBy ?? this.createdBy,
      memberUids: memberUids ?? this.memberUids,
      squadCode: squadCode ?? this.squadCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamerGroupModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
