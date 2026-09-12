import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import 'bouncy_tap.dart';

enum RandomFilter { all, favorites, quick, epic, withFriends }

class RandomGameSheet extends StatefulWidget {
  final List<GameModel> games;
  final DuwaThemeData duwaTheme;
  final ValueChanged<GameModel> onPlanGame;

  const RandomGameSheet({
    super.key,
    required this.games,
    required this.duwaTheme,
    required this.onPlanGame,
  });

  static void show(
    BuildContext context, {
    required List<GameModel> games,
    required DuwaThemeData duwaTheme,
    required ValueChanged<GameModel> onPlanGame,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: duwaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => RandomGameSheet(
        games: games,
        duwaTheme: duwaTheme,
        onPlanGame: onPlanGame,
      ),
    );
  }

  @override
  State<RandomGameSheet> createState() => _RandomGameSheetState();
}

class _RandomGameSheetState extends State<RandomGameSheet>
    with SingleTickerProviderStateMixin {
  RandomFilter _filter = RandomFilter.all;
  GameModel? _selectedGame;
  bool _isShuffling = false;
  late final AnimationController _animController;
  Timer? _shuffleTimer;
  int _shuffleTick = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Pick initial game
    _startShuffle();
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  List<GameModel> get _filteredPool {
    final pool = widget.games.isNotEmpty
        ? widget.games
        : GameNightViewModel.defaultCatalog;

    switch (_filter) {
      case RandomFilter.all:
        return pool;
      case RandomFilter.favorites:
        final favs = pool.where((g) => g.votes > 0).toList();
        return favs.isNotEmpty ? favs : pool;
      case RandomFilter.quick:
        return pool.where((g) {
          final count = g.playerCountRecommendation.toLowerCase();
          return count.contains('1-4') || count.contains('short') || count.contains('casual');
        }).toList().ifEmpty(pool);
      case RandomFilter.epic:
        return pool.where((g) {
          final genre = g.genre.toLowerCase();
          return genre.contains('rpg') || genre.contains('strategy') || genre.contains('moba');
        }).toList().ifEmpty(pool);
      case RandomFilter.withFriends:
        return pool.where((g) {
          final count = g.playerCountRecommendation.toLowerCase();
          return count.contains('4') || count.contains('5') || count.contains('6') || count.contains('squad') || count.contains('party');
        }).toList().ifEmpty(pool);
    }
  }

  void _startShuffle() {
    final pool = _filteredPool;
    if (pool.isEmpty) return;

    _shuffleTimer?.cancel();
    setState(() {
      _isShuffling = true;
      _shuffleTick = 0;
    });

    HapticFeedback.mediumImpact();
    final random = math.Random();

    // Fast timer ticking through 8 cards then settling
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        _shuffleTick++;
        _selectedGame = pool[random.nextInt(pool.length)];
      });

      if (_shuffleTick >= 9) {
        timer.cancel();
        setState(() {
          _isShuffling = false;
        });
        HapticFeedback.heavyImpact();
        _animController.forward(from: 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    final game = _selectedGame ?? (_filteredPool.isNotEmpty ? _filteredPool.first : GameNightViewModel.defaultCatalog.first);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with mascot
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.casino_rounded,
                    color: t.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What should we play?',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Need inspiration? Let DUWA roll for your squad.',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All Games', RandomFilter.all, t),
                  const SizedBox(width: 8),
                  _filterChip('⭐ Favorites', RandomFilter.favorites, t),
                  const SizedBox(width: 8),
                  _filterChip('⚡ Quick Session', RandomFilter.quick, t),
                  const SizedBox(width: 8),
                  _filterChip('🛡️ Epic Session', RandomFilter.epic, t),
                  const SizedBox(width: 8),
                  _filterChip('👥 With Friends', RandomFilter.withFriends, t),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Recommendation Card / Reveal Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isShuffling
                      ? t.primaryAccent.withAlpha(120)
                      : t.cardBorder,
                  width: _isShuffling ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(t.isDark ? 50 : 15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _isShuffling ? 'Shuffling games...' : 'How about...',
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Game Card Presentation
                  Row(
                    children: [
                      // Artwork / Thumbnail
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: t.surfaceLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: game.displayCoverUrl != null && game.displayCoverUrl!.isNotEmpty
                            ? Image.network(
                                game.displayCoverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(game.emoji, style: const TextStyle(fontSize: 32)),
                                ),
                              )
                            : Center(
                                child: Text(game.emoji, style: const TextStyle(fontSize: 32)),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: t.cardBorder),
                                  ),
                                  child: Text(
                                    game.genre.toUpperCase(),
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    game.playerCountRecommendation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                // Shuffle again button
                Expanded(
                  flex: 1,
                  child: BouncyTap(
                    onTap: _isShuffling ? null : _startShuffle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: t.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          '🎲 Roll again',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Primary CTA: Plan it
                Expanded(
                  flex: 2,
                  child: BouncyTap(
                    onTap: _isShuffling
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.onPlanGame(game);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: t.primaryAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: t.primaryAccent.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Plan it →',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, RandomFilter filter, DuwaThemeData t) {
    final isSelected = _filter == filter;
    return BouncyTap(
      onTap: () {
        if (_filter == filter) return;
        setState(() {
          _filter = filter;
        });
        _startShuffle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? t.primaryAccent : t.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? t.primaryAccent : t.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : t.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

extension _ListExt<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) => isEmpty ? fallback : this;
}
