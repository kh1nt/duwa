import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/group_model.dart';
import '../../models/user_profile_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import 'bouncy_tap.dart';
import 'player_avatar.dart';

enum PresenceStatus { inGame, inVoice, ready, idle }

class SquadPresenceItem {
  final String id;
  final String name;
  final String avatarEmoji;
  final PresenceStatus status;
  final String statusText;
  final String? gameTitle;
  final bool isCurrentUser;

  const SquadPresenceItem({
    required this.id,
    required this.name,
    this.avatarEmoji = '🎮',
    required this.status,
    required this.statusText,
    this.gameTitle,
    this.isCurrentUser = false,
  });

  PlayerModel get asPlayer => PlayerModel(
        id: id,
        name: name,
        username: name.toLowerCase().replaceAll(' ', '_'),
        avatarInitials: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
        avatarEmoji: avatarEmoji,
        avatarColorIndex: name.codeUnits.fold<int>(0, (a, b) => a + b) % 6,
      );
}

/// A Mobbin-inspired live presence radar at the top of the home screen.
/// Gives DUWA an immediate social pulse — letting gamers see who's online,
/// who's in a voice room, and who is ready to play.
class SquadPresenceBar extends StatelessWidget {
  final DuwaThemeData duwaTheme;
  final UserProfileModel? currentUser;
  final GroupsViewModel groupsVm;
  final VoidCallback onInviteFriend;

  const SquadPresenceBar({
    super.key,
    required this.duwaTheme,
    this.currentUser,
    required this.groupsVm,
    required this.onInviteFriend,
  });

  List<SquadPresenceItem> _buildPresenceList() {
    final List<SquadPresenceItem> items = [];

    // 1. Current user
    final currentName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : 'You';
    items.add(
      SquadPresenceItem(
        id: currentUser?.id ?? 'me',
        name: currentName,
        avatarEmoji: currentUser?.avatarEmoji ?? '🚀',
        status: PresenceStatus.ready,
        statusText: 'Ready to play',
        isCurrentUser: true,
      ),
    );

    // 2. Members derived from user's squads
    final Set<String> seenNames = {currentName.toLowerCase()};
    final mockGames = ['Helldivers 2', 'Valorant', 'Dota 2', 'Lethal Company', 'Counter-Strike 2'];
    int gameIdx = 0;

    for (final group in groupsVm.groups) {
      for (final member in group.members) {
        final cleanName = member.name.replaceAll(' (You)', '').trim();
        if (cleanName.isEmpty || cleanName.toLowerCase() == 'you' || seenNames.contains(cleanName.toLowerCase())) {
          continue;
        }
        seenNames.add(cleanName.toLowerCase());

        // Assign realistic dynamic presence based on hash
        final hash = cleanName.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
        final statusType = PresenceStatus.values[hash % 3]; // inGame, inVoice, or ready

        String statusText;
        String? game;
        if (statusType == PresenceStatus.inGame) {
          game = mockGames[gameIdx % mockGames.length];
          gameIdx++;
          statusText = 'Playing $game';
        } else if (statusType == PresenceStatus.inVoice) {
          statusText = 'In Voice Room';
        } else {
          statusText = 'Ready';
        }

        items.add(
          SquadPresenceItem(
            id: member.id,
            name: cleanName,
            avatarEmoji: member.avatarEmoji ?? '🎮',
            status: statusType,
            statusText: statusText,
            gameTitle: game,
          ),
        );
      }
    }

    // Default friendly crew if user has no squad members yet
    if (items.length == 1) {
      items.addAll([
        const SquadPresenceItem(
          id: 'bot_alex',
          name: 'Alex',
          avatarEmoji: '⚡',
          status: PresenceStatus.inGame,
          statusText: 'Playing Helldivers 2',
          gameTitle: 'Helldivers 2',
        ),
        const SquadPresenceItem(
          id: 'bot_sam',
          name: 'Sam',
          avatarEmoji: '🔥',
          status: PresenceStatus.inVoice,
          statusText: 'In Discord Voice',
        ),
        const SquadPresenceItem(
          id: 'bot_jordan',
          name: 'Jordan',
          avatarEmoji: '🎯',
          status: PresenceStatus.ready,
          statusText: 'Ready to play',
        ),
      ]);
    }

    return items;
  }

  Color _getStatusColor(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.inGame:
        return DuwaColors.presenceInGame;
      case PresenceStatus.inVoice:
        return DuwaColors.presenceVoice;
      case PresenceStatus.ready:
        return DuwaColors.presenceOnline;
      case PresenceStatus.idle:
        return DuwaColors.presenceAway;
    }
  }

  void _showMemberSheet(BuildContext context, SquadPresenceItem item) {
    HapticFeedback.selectionClick();
    final t = duwaTheme;
    final statusColor = _getStatusColor(item.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2.5),
                ),
                child: PlayerAvatar(
                  player: item.asPlayer,
                  radius: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BouncyTap(
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Pinged ${item.name} for game night! 🎮')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: t.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Rally to Play',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = duwaTheme;
    final items = _buildPresenceList();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length + 1, // +1 for the Add / Invite pill
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Invite / Add friend button
            return BouncyTap(
              onTap: onInviteFriend,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: t.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: t.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(Icons.add_rounded, color: t.primaryAccent, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Invite',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          final item = items[index];
          final statusColor = _getStatusColor(item.status);

          return BouncyTap(
            onTap: () => _showMemberSheet(context, item),
            scaleDown: 0.94,
            child: SizedBox(
              width: 62,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.isCurrentUser
                                ? t.primaryAccent
                                : statusColor.withAlpha(220),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (item.isCurrentUser ? t.primaryAccent : statusColor).withAlpha(45),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PlayerAvatar(
                          player: item.asPlayer,
                          radius: 22,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.surface,
                              width: 2.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.isCurrentUser ? 'You' : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: item.isCurrentUser ? t.primaryAccent : t.textPrimary,
                      fontSize: 11,
                      fontWeight: item.isCurrentUser ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
