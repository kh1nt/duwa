import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../common/bouncy_tap.dart';

/// Streamlined & Minimalist Steam Quick Sync
/// Allows players to optionally link Steam and 1-tap nominate co-op games into squad sessions
class SteamIntegrationView extends StatefulWidget {
  final ProfileViewModel profileVm;
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;

  const SteamIntegrationView({
    super.key,
    required this.profileVm,
    required this.gameNightVm,
    required this.duwaTheme,
  });

  @override
  State<SteamIntegrationView> createState() => _SteamIntegrationViewState();
}

class _SteamIntegrationViewState extends State<SteamIntegrationView> {
  final TextEditingController _steamIdController = TextEditingController();

  static const List<GameModel> _popularSquadSteamGames = [
    GameModel(
      id: 'steam-cs2',
      title: 'Counter-Strike 2',
      genre: 'Tactical Shooter',
      emoji: '🎯',
      bannerGradientStart: '#E58E26',
      bannerGradientEnd: '#F6B93B',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&auto=format&fit=crop&q=80',
    ),
    GameModel(
      id: 'steam-hd2',
      title: 'Helldivers 2',
      genre: 'Co-op PVE Shooter',
      emoji: '🚀',
      bannerGradientStart: '#F59E0B',
      bannerGradientEnd: '#EF4444',
      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80',
    ),
    GameModel(
      id: 'steam-dota2',
      title: 'Dota 2',
      genre: 'MOBA',
      emoji: '⚔️',
      bannerGradientStart: '#B91C1C',
      bannerGradientEnd: '#7F1D1D',
      imageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=600&auto=format&fit=crop&q=80',
    ),
    GameModel(
      id: 'steam-lethal',
      title: 'Lethal Company',
      genre: 'Horror Co-op',
      emoji: '🔦',
      bannerGradientStart: '#B45309',
      bannerGradientEnd: '#1F2937',
      imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&auto=format&fit=crop&q=80',
    ),
    GameModel(
      id: 'steam-phasmo',
      title: 'Phasmophobia',
      genre: 'Psychological Horror',
      emoji: '👻',
      bannerGradientStart: '#4B5563',
      bannerGradientEnd: '#111827',
      imageUrl: 'https://images.unsplash.com/photo-1579373903781-fd5c0c30c4cd?w=600&auto=format&fit=crop&q=80',
    ),
  ];

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  void _nominateGame(GameModel game) {
    HapticFeedback.lightImpact();
    final added = widget.gameNightVm.nominateGameForVoting(game);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Added ${game.title} to squad session voting! 🗳️'
              : '${game.title} is already nominated.',
        ),
        backgroundColor: widget.duwaTheme.primaryAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    final isConnected = widget.profileVm.isSteamConnected;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        title: const Text('Steam Sync', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: t.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171A21),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: const Icon(LucideIcons.gamepad2, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Steam Account',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConnected
                                ? 'Connected as ${widget.profileVm.profile.displayName}'
                                : 'Optional: Sync games for squad votes',
                            style: TextStyle(color: t.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isConnected,
                      activeColor: DuwaColors.ionMint,
                      onChanged: (_) {
                        widget.profileVm.toggleSteamConnection();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (isConnected) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DuwaColors.ionMint.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DuwaColors.ionMint.withAlpha(60)),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 14, color: DuwaColors.ionMint),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Library synced · Co-op games ready to nominate',
                            style: TextStyle(color: DuwaColors.ionMint, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Games Quick List
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 16, color: DuwaColors.blueIris),
              const SizedBox(width: 8),
              Text(
                'CO-OP SQUAD FAVORITES',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._popularSquadSteamGames.map((game) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: t.surfaceHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(game.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.genre,
                          style: TextStyle(color: t.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  BouncyTap(
                    onTap: () => _nominateGame(game),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.surfaceHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.plus, size: 14, color: t.primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Nominate',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
