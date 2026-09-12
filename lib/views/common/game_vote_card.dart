import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../models/game_model.dart';
import 'bouncy_tap.dart';
import 'duwa_cards.dart';

class GameVoteCard extends StatelessWidget {
  final GameModel game;
  final int totalSessionVotes;
  final bool isVotedByUser;
  final VoidCallback onVote;

  const GameVoteCard({
    super.key,
    required this.game,
    required this.totalSessionVotes,
    required this.isVotedByUser,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final votePercentage = totalSessionVotes > 0
        ? (game.votes / totalSessionVotes).clamp(0.0, 1.0)
        : 0.0;

    return DuwaCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      border: Border.all(
        color: isVotedByUser ? DuwaColors.blueIris : Colors.white.withAlpha(25),
        width: isVotedByUser ? 1.5 : 1,
      ),
      child: Stack(
        children: [
          // Background animated vote progress fill with smooth easing
          Positioned.fill(
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: game.votes > 0 ? votePercentage : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      DuwaColors.danubeBlue.withAlpha(45),
                      DuwaColors.blueIris.withAlpha(22),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Game Emoji / Banner icon with bouncy tap
                BouncyTap(
                  onTap: onVote,
                  scaleDown: 0.92,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [game.startColor, game.endColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: game.startColor.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      game.emoji,
                      style: const TextStyle(fontSize: 27),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Game Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              game.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (game.isSteamGame) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2838),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF66C0F4).withAlpha(128), width: 0.8),
                              ),
                              child: const Text(
                                'STEAM',
                                style: TextStyle(
                                  color: Color(0xFF66C0F4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        game.genre,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DuwaColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Vote tally indicator & percentage
                      Row(
                        children: [
                          Icon(
                            Icons.how_to_vote,
                            size: 13,
                            color: game.votes > 0 ? DuwaColors.blueIris : DuwaColors.textSubtle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${game.votes} ${game.votes == 1 ? "vote" : "votes"} · ${(votePercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: game.votes > 0 ? DuwaColors.blueIris : DuwaColors.textMuted,
                            ),
                          ),
                          if (isVotedByUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: DuwaColors.blueIris.withAlpha(51),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: DuwaColors.blueIris.withAlpha(100)),
                              ),
                              child: const Text(
                                'Imong boto ✓',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: DuwaColors.blueIris,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Tactile Bouncy Vote button
                BouncyTap(
                  onTap: onVote,
                  scaleDown: 0.92,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isVotedByUser
                          ? const LinearGradient(
                              colors: [DuwaColors.danubeBlue, DuwaColors.blueIris],
                            )
                          : null,
                      color: isVotedByUser ? null : Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isVotedByUser ? Colors.transparent : Colors.white.withAlpha(38),
                      ),
                      boxShadow: isVotedByUser
                          ? [
                              BoxShadow(
                                color: DuwaColors.blueIris.withAlpha(80),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      isVotedByUser ? 'Voted' : 'Vote',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isVotedByUser ? DuwaColors.mysticBlue : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
