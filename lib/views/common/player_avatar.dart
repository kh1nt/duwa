import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../models/group_model.dart';

const List<List<Color>> avatarGradients = [
  [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue
  [Color(0xFF10B981), Color(0xFF047857)], // Green
  [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
  [Color(0xFFEC4899), Color(0xFFBE185D)], // Pink
  [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple
  [Color(0xFF06B6D4), Color(0xFF0E7490)], // Cyan
];

class PlayerAvatar extends StatelessWidget {
  final PlayerModel player;
  final double radius;
  final bool showStatusDot;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.radius = 18,
    this.showStatusDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = avatarGradients[player.avatarColorIndex % avatarGradients.length];

    Color statusColor;
    switch (player.rsvp) {
      case RSVPStatus.going:
        statusColor = DuwaColors.successGreen;
        break;
      case RSVPStatus.maybe:
        statusColor = DuwaColors.warningOrange;
        break;
      case RSVPStatus.cantGo:
        statusColor = DuwaColors.errorRed;
        break;
      case RSVPStatus.pending:
        statusColor = Colors.transparent;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            player.avatarInitials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.75,
            ),
          ),
        ),
        if (showStatusDot && player.rsvp != RSVPStatus.pending)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: radius * 0.7,
              height: radius * 0.7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: DuwaColors.mysticBlue, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class AvatarGroup extends StatelessWidget {
  final List<PlayerModel> players;
  final int maxVisible;
  final double radius;
  final bool showStatusDot;

  const AvatarGroup({
    super.key,
    required this.players,
    this.maxVisible = 4,
    this.radius = 16,
    this.showStatusDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = players.take(maxVisible).toList();
    final remainingCount = players.length - maxVisible;

    return SizedBox(
      height: radius * 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < visiblePlayers.length; i++)
            Align(
              widthFactor: 0.75,
              child: PlayerAvatar(
                player: visiblePlayers[i],
                radius: radius,
                showStatusDot: showStatusDot,
              ),
            ),
          if (remainingCount > 0)
            Align(
              widthFactor: 0.75,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.65,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
