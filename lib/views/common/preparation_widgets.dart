import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import 'duwa_cards.dart';

class PreparationSummaryWidget extends StatelessWidget {
  final GameNightModel gameNight;
  final DuwaThemeData? duwaTheme;
  final Function(String itemId)? onToggleChecklist;
  final Function(String itemId)? onClaimItem;

  const PreparationSummaryWidget({
    super.key,
    required this.gameNight,
    this.duwaTheme,
    this.onToggleChecklist,
    this.onClaimItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = duwaTheme ?? DuwaThemeData.obsidianVoid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🍕 Food & Drinks Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Card
            Expanded(
              child: DuwaCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🍕', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          'Food',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (gameNight.food?.isReady == true)
                          const Icon(Icons.check_circle_rounded, size: 14, color: DuwaColors.successGreen),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameNight.food?.title ?? 'No food planned yet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: gameNight.food != null ? theme.textPrimary : theme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gameNight.food?.buyerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By: ${gameNight.food!.buyerName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.primaryAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Drinks Card
            Expanded(
              child: DuwaCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🥤', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          'Drinks',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (gameNight.drinks?.isReady == true)
                          const Icon(Icons.check_circle_rounded, size: 14, color: DuwaColors.successGreen),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameNight.drinks != null && gameNight.drinks!.items.isNotEmpty
                          ? gameNight.drinks!.items.join(' · ')
                          : 'BYO Drinks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: gameNight.drinks != null ? theme.textPrimary : theme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),


        // 📍 Location Card
        if (gameNight.location != null)
          DuwaCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📍', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameNight.location!.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                        ),
                      ),
                      if (gameNight.location!.detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          gameNight.location!.detail!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (gameNight.location!.isConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DuwaColors.successGreen.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Confirmed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: DuwaColors.successGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),

        // 🎒 Things to Bring / Checklist
        if (gameNight.checklist.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              '🎒 Things to Bring',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.primaryAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...gameNight.checklist.map((item) {
            final isClaimed = item.assignedTo != null && item.assignedTo!.isNotEmpty;
            final isMine = isClaimed && (item.assignedTo == 'You' || item.assignedTo!.contains('(You)'));

            return DuwaCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              onTap: onToggleChecklist != null
                  ? () => onToggleChecklist!(item.id)
                  : null,
              child: Row(
                children: [
                  Checkbox(
                    value: item.isDone,
                    onChanged: onToggleChecklist != null
                        ? (_) => onToggleChecklist!(item.id)
                        : null,
                    activeColor: theme.primaryAccent,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                            color: item.isDone ? theme.textMuted : theme.textPrimary,
                          ),
                        ),
                        if (isClaimed) ...[
                          const SizedBox(height: 2),
                          Text(
                            isMine ? 'You\'re bringing this ✓' : 'Brought by ${item.assignedTo} ✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: isMine ? DuwaColors.successGreen : theme.primaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClaimItem != null && !item.isDone)
                    GestureDetector(
                      onTap: () => onClaimItem!(item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isMine
                              ? DuwaColors.successGreen.withAlpha(30)
                              : (isClaimed ? theme.surfaceLight : theme.primaryAccent),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isMine
                                ? DuwaColors.successGreen.withAlpha(100)
                                : (isClaimed ? theme.cardBorder : Colors.transparent),
                          ),
                        ),
                        child: Text(
                          isMine ? 'Claimed ✓' : (isClaimed ? item.assignedTo! : 'I\'ll bring this'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMine ? DuwaColors.successGreen : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
