import 'package:flutter/material.dart';
import '../services/cloudinary_service.dart';

class GameModel {
  final String id;
  final String title;
  final String genre;
  final String emoji;
  final String bannerGradientStart;
  final String bannerGradientEnd;
  final int votes;
  final List<String> voterAvatars;
  final bool isSteamGame;
  final String playerCountRecommendation;
  final int? steamAppId;
  final int playtimeHours;
  final double recentPlaytimeHours;
  final int squadOwnersCount;
  final int squadTotalCount;
  final List<String> squadOwnerAvatars;
  final String steamDeckStatus; // 'verified', 'playable', 'unsupported'
  final String coopType;
  final String? imageUrl;
  final bool isInstalled;
  final String? createdBy;

  const GameModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.emoji,
    required this.bannerGradientStart,
    required this.bannerGradientEnd,
    this.votes = 0,
    this.voterAvatars = const [],
    this.isSteamGame = false,
    this.playerCountRecommendation = '4-10 players',
    this.steamAppId,
    this.playtimeHours = 0,
    this.recentPlaytimeHours = 0.0,
    this.squadOwnersCount = 0,
    this.squadTotalCount = 5,
    this.squadOwnerAvatars = const [],
    this.steamDeckStatus = 'verified',
    this.coopType = 'Online Co-op',
    this.imageUrl,
    this.isInstalled = false,
    this.createdBy,
  });

  GameModel copyWith({
    String? id,
    String? title,
    String? genre,
    String? emoji,
    String? bannerGradientStart,
    String? bannerGradientEnd,
    int? votes,
    List<String>? voterAvatars,
    bool? isSteamGame,
    String? playerCountRecommendation,
    int? steamAppId,
    int? playtimeHours,
    double? recentPlaytimeHours,
    int? squadOwnersCount,
    int? squadTotalCount,
    List<String>? squadOwnerAvatars,
    String? steamDeckStatus,
    String? coopType,
    String? imageUrl,
    bool? isInstalled,
    String? createdBy,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      emoji: emoji ?? this.emoji,
      bannerGradientStart: bannerGradientStart ?? this.bannerGradientStart,
      bannerGradientEnd: bannerGradientEnd ?? this.bannerGradientEnd,
      votes: votes ?? this.votes,
      voterAvatars: voterAvatars ?? this.voterAvatars,
      isSteamGame: isSteamGame ?? this.isSteamGame,
      playerCountRecommendation: playerCountRecommendation ?? this.playerCountRecommendation,
      steamAppId: steamAppId ?? this.steamAppId,
      playtimeHours: playtimeHours ?? this.playtimeHours,
      recentPlaytimeHours: recentPlaytimeHours ?? this.recentPlaytimeHours,
      squadOwnersCount: squadOwnersCount ?? this.squadOwnersCount,
      squadTotalCount: squadTotalCount ?? this.squadTotalCount,
      squadOwnerAvatars: squadOwnerAvatars ?? this.squadOwnerAvatars,
      steamDeckStatus: steamDeckStatus ?? this.steamDeckStatus,
      coopType: coopType ?? this.coopType,
      imageUrl: imageUrl ?? this.imageUrl,
      isInstalled: isInstalled ?? this.isInstalled,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Color get startColor => Color(int.parse(bannerGradientStart.replaceFirst('#', '0xFF')));
  Color get endColor => Color(int.parse(bannerGradientEnd.replaceFirst('#', '0xFF')));

  bool get is100PercentSquadMatch => squadOwnersCount >= squadTotalCount && squadTotalCount > 0;

  String? get displayCoverUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (steamAppId != null && steamAppId! > 0) {
      return 'https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/header.jpg';
    }
    return null;
  }

  /// Returns an optimized cover URL with Cloudinary transformations if applicable
  String? optimizedCoverUrl({int? width, int? height, String crop = 'fill'}) {
    final raw = displayCoverUrl;
    if (raw == null) return null;
    if (raw.contains('res.cloudinary.com')) {
      return CloudinaryService().getOptimizedUrl(raw, width: width, height: height, crop: crop);
    }
    return raw;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'genre': genre,
      'emoji': emoji,
      'bannerGradientStart': bannerGradientStart,
      'bannerGradientEnd': bannerGradientEnd,
      'votes': votes,
      'voterAvatars': voterAvatars,
      'isSteamGame': isSteamGame,
      'playerCountRecommendation': playerCountRecommendation,
      'steamAppId': steamAppId,
      'playtimeHours': playtimeHours,
      'recentPlaytimeHours': recentPlaytimeHours,
      'squadOwnersCount': squadOwnersCount,
      'squadTotalCount': squadTotalCount,
      'squadOwnerAvatars': squadOwnerAvatars,
      'steamDeckStatus': steamDeckStatus,
      'coopType': coopType,
      'imageUrl': imageUrl,
      'isInstalled': isInstalled,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map, String id) {
    return GameModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled Game',
      genre: map['genre'] as String? ?? 'General Game',
      emoji: map['emoji'] as String? ?? '🎮',
      bannerGradientStart: map['bannerGradientStart'] as String? ?? '#4F46E5',
      bannerGradientEnd: map['bannerGradientEnd'] as String? ?? '#1E1B4B',
      votes: (map['votes'] as num?)?.toInt() ?? 0,
      voterAvatars: (map['voterAvatars'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isSteamGame: map['isSteamGame'] as bool? ?? false,
      playerCountRecommendation: map['playerCountRecommendation'] as String? ?? '2-8 players',
      steamAppId: (map['steamAppId'] as num?)?.toInt(),
      playtimeHours: (map['playtimeHours'] as num?)?.toInt() ?? 0,
      recentPlaytimeHours: (map['recentPlaytimeHours'] as num?)?.toDouble() ?? 0.0,
      squadOwnersCount: (map['squadOwnersCount'] as num?)?.toInt() ?? 0,
      squadTotalCount: (map['squadTotalCount'] as num?)?.toInt() ?? 5,
      squadOwnerAvatars: (map['squadOwnerAvatars'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      steamDeckStatus: map['steamDeckStatus'] as String? ?? 'verified',
      coopType: map['coopType'] as String? ?? 'Online Co-op',
      imageUrl: map['imageUrl'] as String?,
      isInstalled: map['isInstalled'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameModel && runtimeType == other.runtimeType && id == other.id;

  String get platform => isSteamGame ? 'PC (Steam)' : 'Crossplay / Multi';

  @override
  int get hashCode => id.hashCode;
}
