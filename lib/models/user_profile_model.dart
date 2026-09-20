class UserProfileModel {
  final String id;
  final String displayName;
  final String handle;
  final String bio;
  final String avatarInitials;
  final String avatarEmoji;
  final String? photoUrl;
  final List<String> favoriteGames;
  final int gameNightsHosted;
  final int gameNightsPlayed;
  final bool isSteamConnected;
  final String? steamPersonaName;
  final int steamGamesCount;
  final String? steamFriendCode;
  final int steamLevel;
  final String? steamStatus;
  final double steamRecentHours;
  final String? lastSteamSync;

  const UserProfileModel({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.avatarInitials,
    this.avatarEmoji = '🎮',
    this.photoUrl,
    this.favoriteGames = const [],
    this.gameNightsHosted = 0,
    this.gameNightsPlayed = 0,
    this.isSteamConnected = false,
    this.steamPersonaName,
    this.steamGamesCount = 0,
    this.steamFriendCode,
    this.steamLevel = 1,
    this.steamStatus,
    this.steamRecentHours = 0.0,
    this.lastSteamSync,
  });

  UserProfileModel copyWith({
    String? id,
    String? displayName,
    String? handle,
    String? bio,
    String? avatarInitials,
    String? avatarEmoji,
    String? photoUrl,
    List<String>? favoriteGames,
    int? gameNightsHosted,
    int? gameNightsPlayed,
    bool? isSteamConnected,
    String? steamPersonaName,
    int? steamGamesCount,
    String? steamFriendCode,
    int? steamLevel,
    String? steamStatus,
    double? steamRecentHours,
    String? lastSteamSync,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteGames: favoriteGames ?? this.favoriteGames,
      gameNightsHosted: gameNightsHosted ?? this.gameNightsHosted,
      gameNightsPlayed: gameNightsPlayed ?? this.gameNightsPlayed,
      isSteamConnected: isSteamConnected ?? this.isSteamConnected,
      steamPersonaName: steamPersonaName ?? this.steamPersonaName,
      steamGamesCount: steamGamesCount ?? this.steamGamesCount,
      steamFriendCode: steamFriendCode ?? this.steamFriendCode,
      steamLevel: steamLevel ?? this.steamLevel,
      steamStatus: steamStatus ?? this.steamStatus,
      steamRecentHours: steamRecentHours ?? this.steamRecentHours,
      lastSteamSync: lastSteamSync ?? this.lastSteamSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'handle': handle,
      'bio': bio,
      'avatarInitials': avatarInitials,
      'avatarEmoji': avatarEmoji,
      'photoUrl': photoUrl,
      'favoriteGames': favoriteGames,
      'gameNightsHosted': gameNightsHosted,
      'gameNightsPlayed': gameNightsPlayed,
      'isSteamConnected': isSteamConnected,
      'steamPersonaName': steamPersonaName,
      'steamGamesCount': steamGamesCount,
      'steamFriendCode': steamFriendCode,
      'steamLevel': steamLevel,
      'steamStatus': steamStatus,
      'steamRecentHours': steamRecentHours,
      'lastSteamSync': lastSteamSync,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserProfileModel(
      id: docId ?? map['id'] as String? ?? 'user-default',
      displayName: map['displayName'] as String? ?? 'Player',
      handle: map['handle'] as String? ?? '@gamer',
      bio: map['bio'] as String? ?? 'Ready to squad up · Let\'s play 🎮',
      avatarInitials: map['avatarInitials'] as String? ?? 'P',
      avatarEmoji: map['avatarEmoji'] as String? ?? '🎮',
      photoUrl: map['photoUrl'] as String?,
      favoriteGames: (map['favoriteGames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      gameNightsHosted: (map['gameNightsHosted'] as num?)?.toInt() ?? 0,
      gameNightsPlayed: (map['gameNightsPlayed'] as num?)?.toInt() ?? 0,
      isSteamConnected: map['isSteamConnected'] as bool? ?? false,
      steamPersonaName: map['steamPersonaName'] as String?,
      steamGamesCount: (map['steamGamesCount'] as num?)?.toInt() ?? 0,
      steamFriendCode: map['steamFriendCode'] as String?,
      steamLevel: (map['steamLevel'] as num?)?.toInt() ?? 1,
      steamStatus: map['steamStatus'] as String?,
      steamRecentHours: (map['steamRecentHours'] as num?)?.toDouble() ?? 0.0,
      lastSteamSync: map['lastSteamSync'] as String?,
    );
  }
}
