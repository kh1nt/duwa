import 'dart:math' as math;
import 'game_model.dart';
import 'group_model.dart';

enum GameNightStatus {
  draft,
  voting,
  planning,
  ready,
  completed,
  cancelled,
}

class FoodPrepModel {
  final String title;
  final String? buyerName;
  final bool isReady;

  const FoodPrepModel({
    required this.title,
    this.buyerName,
    this.isReady = false,
  });

  FoodPrepModel copyWith({
    String? title,
    String? buyerName,
    bool? isReady,
  }) {
    return FoodPrepModel(
      title: title ?? this.title,
      buyerName: buyerName ?? this.buyerName,
      isReady: isReady ?? this.isReady,
    );
  }
}

class DrinkPrepModel {
  final List<String> items;
  final bool isReady;

  const DrinkPrepModel({
    this.items = const [],
    this.isReady = false,
  });

  DrinkPrepModel copyWith({
    List<String>? items,
    bool? isReady,
  }) {
    return DrinkPrepModel(
      items: items ?? this.items,
      isReady: isReady ?? this.isReady,
    );
  }
}

class LocationPrepModel {
  final String name;
  final String? detail;
  final bool isConfirmed;

  const LocationPrepModel({
    required this.name,
    this.detail,
    this.isConfirmed = false,
  });

  LocationPrepModel copyWith({
    String? name,
    String? detail,
    bool? isConfirmed,
  }) {
    return LocationPrepModel(
      name: name ?? this.name,
      detail: detail ?? this.detail,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

class ChecklistItemModel {
  final String id;
  final String title;
  final bool isDone;
  final String? assignedTo;

  const ChecklistItemModel({
    required this.id,
    required this.title,
    this.isDone = false,
    this.assignedTo,
  });

  ChecklistItemModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? assignedTo,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

class GameNightModel {
  final String id;
  final String title;
  final GamerGroupModel group;
  final DateTime? scheduledDateTime;
  final String formattedDate;
  final String formattedTime;
  final GameNightStatus status;
  final GameModel? selectedGame;
  final List<GameModel> votingGames;
  final String? userVotedGameId;
  final List<PlayerModel> players;
  final FoodPrepModel? food;
  final DrinkPrepModel? drinks;
  final LocationPrepModel? location;
  final List<ChecklistItemModel> checklist;
  final bool isHost;
  final String? organizerName;
  final String? roomCode;
  final String? historyHighlight; // e.g. "MVP: You", "Win (32m)", "Completed"
  final String? subdetail;        // e.g. "Last Tuesday • 4 Duwaonon • 3-star streak"
  final String? voiceChannelUrl;  // e.g. Discord voice link or Meet URL
  final String? createdBy;
  final List<String> playerUids;

  const GameNightModel({
    required this.id,
    required this.title,
    required this.group,
    this.scheduledDateTime,
    required this.formattedDate,
    required this.formattedTime,
    required this.status,
    this.selectedGame,
    this.votingGames = const [],
    this.userVotedGameId,
    required this.players,
    this.food,
    this.drinks,
    this.location,
    this.checklist = const [],
    this.isHost = false,
    this.organizerName,
    this.roomCode,
    this.historyHighlight,
    this.subdetail,
    this.voiceChannelUrl,
    this.createdBy,
    this.playerUids = const [],
  });

  String get displayRoomCode => (roomCode != null && roomCode!.isNotEmpty)
      ? roomCode!
      : 'DUWA-${id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase()}';

  String get organizerDisplay => organizerName ?? (isHost ? 'You' : (players.isNotEmpty ? players.first.name : 'Squad'));

  int get goingCount => players.where((p) => p.rsvp == RSVPStatus.going).length;
  int get maybeCount => players.where((p) => p.rsvp == RSVPStatus.maybe).length;
  int get cantGoCount => players.where((p) => p.rsvp == RSVPStatus.cantGo).length;

  String get timeFormatted => formattedTime;
  String get countdownFormatted => 'Starts $formattedTime';
  bool get isTonight =>
      formattedDate.toLowerCase().contains('today') ||
      formattedDate.toLowerCase().contains('tonight');
  String get weekdayShort => formattedDate.split(',').first;
  /// Dynamic squad size: accommodates squad growth gracefully without an artificial 5-player cap
  int get maxPlayers => math.max(players.length >= 6 ? players.length + 2 : 8, players.length);
  String get description => subdetail ?? historyHighlight ?? '';
  bool get hasVoiceChannel => voiceChannelUrl != null && voiceChannelUrl!.trim().isNotEmpty;

  GameNightModel copyWith({
    String? id,
    String? title,
    GamerGroupModel? group,
    DateTime? scheduledDateTime,
    String? formattedDate,
    String? formattedTime,
    GameNightStatus? status,
    GameModel? selectedGame,
    List<GameModel>? votingGames,
    String? userVotedGameId,
    List<PlayerModel>? players,
    FoodPrepModel? food,
    DrinkPrepModel? drinks,
    LocationPrepModel? location,
    List<ChecklistItemModel>? checklist,
    bool? isHost,
    String? organizerName,
    String? roomCode,
    String? historyHighlight,
    String? subdetail,
    String? voiceChannelUrl,
    String? createdBy,
    List<String>? playerUids,
  }) {
    return GameNightModel(
      id: id ?? this.id,
      title: title ?? this.title,
      group: group ?? this.group,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      formattedDate: formattedDate ?? this.formattedDate,
      formattedTime: formattedTime ?? this.formattedTime,
      status: status ?? this.status,
      selectedGame: selectedGame ?? this.selectedGame,
      votingGames: votingGames ?? this.votingGames,
      userVotedGameId: userVotedGameId ?? this.userVotedGameId,
      players: players ?? this.players,
      food: food ?? this.food,
      drinks: drinks ?? this.drinks,
      location: location ?? this.location,
      checklist: checklist ?? this.checklist,
      isHost: isHost ?? this.isHost,
      organizerName: organizerName ?? this.organizerName,
      roomCode: roomCode ?? this.roomCode,
      historyHighlight: historyHighlight ?? this.historyHighlight,
      subdetail: subdetail ?? this.subdetail,
      voiceChannelUrl: voiceChannelUrl ?? this.voiceChannelUrl,
      createdBy: createdBy ?? this.createdBy,
      playerUids: playerUids ?? this.playerUids,
    );
  }
}
