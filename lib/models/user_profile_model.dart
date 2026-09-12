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
}
