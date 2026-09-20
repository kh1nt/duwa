import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/config/steam_config.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../services/preferences_service.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../common/bouncy_tap.dart';

/// Impeccable Steam Quick Sync & Library Integration
/// Connects to Valve's live Web API to sync player games, playtime, and official Steam CDN art.
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
  late final TextEditingController _steamIdController;
  late final TextEditingController _apiKeyController;
  final TextEditingController _searchController = TextEditingController();
  bool _showApiConfig = false;

  static const List<GameModel> _popularSquadSteamGames = [
    GameModel(
      id: 'steam-cs2',
      title: 'Counter-Strike 2',
      genre: 'Tactical Shooter · Valve',
      emoji: '🎯',
      bannerGradientStart: '#E58E26',
      bannerGradientEnd: '#F6B93B',
      isSteamGame: true,
      steamAppId: 730,
      imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg',
    ),
    GameModel(
      id: 'steam-hd2',
      title: 'Helldivers 2',
      genre: 'Co-op PVE Shooter · Arrowhead',
      emoji: '🚀',
      bannerGradientStart: '#F59E0B',
      bannerGradientEnd: '#EF4444',
      isSteamGame: true,
      steamAppId: 553850,
      imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/553850/header.jpg',
    ),
    GameModel(
      id: 'steam-dota2',
      title: 'Dota 2',
      genre: 'Competitive MOBA · Valve',
      emoji: '⚔️',
      bannerGradientStart: '#B91C1C',
      bannerGradientEnd: '#7F1D1D',
      isSteamGame: true,
      steamAppId: 570,
      imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg',
    ),
    GameModel(
      id: 'steam-lethal',
      title: 'Lethal Company',
      genre: 'Horror Co-op Scavenger · Zeekerss',
      emoji: '🔦',
      bannerGradientStart: '#B45309',
      bannerGradientEnd: '#1F2937',
      isSteamGame: true,
      steamAppId: 1966720,
      imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/1966720/header.jpg',
    ),
    GameModel(
      id: 'steam-phasmo',
      title: 'Phasmophobia',
      genre: 'Ghost Hunting Co-op · Kinetic',
      emoji: '👻',
      bannerGradientStart: '#4B5563',
      bannerGradientEnd: '#111827',
      isSteamGame: true,
      steamAppId: 739630,
      imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/739630/header.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialId = widget.profileVm.profile.steamFriendCode ??
        PreferencesService().getSteamInputId() ??
        '';
    final initialKey = PreferencesService().getSteamApiKey() ??
        SteamConfig.steamApiKey;

    _steamIdController = TextEditingController(text: initialId);
    _apiKeyController = TextEditingController(text: initialKey);
    _searchController.text = widget.profileVm.steamSearchQuery;
  }

  @override
  void dispose() {
    _steamIdController.dispose();
    _apiKeyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final input = _steamIdController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Steam Friend Code, SteamID64, or vanity profile name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final customKey = _apiKeyController.text.trim();
    final res = await widget.profileVm.connectSteamAccount(
      input: input,
      customApiKey: customKey.isNotEmpty ? customKey : null,
    );

    if (!mounted) return;

    if (res.isSuccess) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to Steam as ${res.profile?.personaName ?? "Steam User"}! Found ${res.games.length} games.',
          ),
          backgroundColor: DuwaColors.ionMint,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to connect to Steam.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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

    return ListenableBuilder(
      listenable: widget.profileVm,
      builder: (context, _) {
        final isConnected = widget.profileVm.isSteamConnected;
        final isSyncing = widget.profileVm.isSyncing;
        final p = widget.profileVm.profile;
        final games = isConnected && widget.profileVm.steamCatalog.isNotEmpty
            ? widget.profileVm.steamCatalog
            : _popularSquadSteamGames;

        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            title: Text(
              'Steam Sync',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: t.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            backgroundColor: t.surface,
            elevation: 0,
            actions: [
              if (isConnected)
                IconButton(
                  tooltip: 'Refresh Library',
                  icon: isSyncing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.primaryAccent,
                          ),
                        )
                      : Icon(LucideIcons.refreshCw, color: t.primaryAccent, size: 18),
                  onPressed: isSyncing ? null : () => widget.profileVm.syncSteamLibrary(),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ==========================================
              // --- ACCOUNT STATUS & CONNECTION CARD ---
              // ==========================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected ? DuwaColors.ionMint.withAlpha(90) : t.cardBorder,
                    width: isConnected ? 1.4 : 1.0,
                  ),
                  boxShadow: DuwaTheme.cozyShadow,
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
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: const Icon(LucideIcons.gamepad2, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Steam Integration',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isConnected
                                    ? 'Connected as ${p.steamPersonaName ?? p.displayName}'
                                    : 'Link Steam to sync owned co-op games for voting',
                                style: TextStyle(
                                  color: isConnected ? DuwaColors.ionMint : t.textSecondary,
                                  fontSize: 13,
                                  fontWeight: isConnected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isConnected,
                          activeColor: DuwaColors.ionMint,
                          onChanged: (_) {
                            widget.profileVm.toggleSteamConnection();
                          },
                        ),
                      ],
                    ),

                    if (!isConnected) ...[
                      const SizedBox(height: 18),
                      Text(
                        'STEAM ACCOUNT (FRIEND CODE OR ID64)',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _steamIdController,
                              style: TextStyle(color: t.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. 87291044 or 76561198...',
                                hintStyle: TextStyle(color: t.textMuted.withAlpha(150), fontSize: 13),
                                filled: true,
                                fillColor: t.surfaceLight,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.primaryAccent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          BouncyTap(
                            onTap: isSyncing ? () {} : _handleConnect,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: t.primaryAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      children: [
                                        Icon(LucideIcons.link, size: 15, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Connect',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: DuwaColors.ionMint.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DuwaColors.ionMint.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle2, size: 16, color: DuwaColors.ionMint),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${p.steamGamesCount} games synced · ${p.steamStatus ?? "Online"}',
                                style: const TextStyle(
                                  color: DuwaColors.ionMint,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            BouncyTap(
                              onTap: () => widget.profileVm.disconnectSteam(),
                              child: Text(
                                'Disconnect',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ==========================================
                    // --- API KEY CONFIG DRAWER ---
                    // ==========================================
                    const SizedBox(height: 16),
                    Divider(height: 1, color: t.cardBorder.withAlpha(120)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _showApiConfig = !_showApiConfig),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.keyRound,
                            size: 14,
                            color: t.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Steam Web API Key Settings',
                              style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            _showApiConfig ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 16,
                            color: t.textMuted,
                          ),
                        ],
                      ),
                    ),

                    if (_showApiConfig) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Required by Valve to query player game libraries. Free from steamcommunity.com/dev/apikey.',
                        style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              style: TextStyle(color: t.textPrimary, fontSize: 13),
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Paste Steam API Key here...',
                                hintStyle: TextStyle(color: t.textMuted.withAlpha(140), fontSize: 12),
                                filled: true,
                                fillColor: t.surfaceLight,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: t.cardBorder),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          BouncyTap(
                            onTap: () {
                              PreferencesService().setSteamApiKey(_apiKeyController.text.trim());
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved Steam Web API Key! 🔑'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: t.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.cardBorder),
                              ),
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.profileVm.steamSyncError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.profileVm.steamSyncError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ==========================================
              // --- GAMES HEADER & SEARCH BAR ---
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, size: 16, color: DuwaColors.blueIris),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? 'YOUR STEAM LIBRARY' : 'CO-OP SQUAD FAVORITES',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${games.length} games',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (isConnected) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (val) => widget.profileVm.setSteamSearchQuery(val),
                  style: TextStyle(color: t.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search games in your Steam library...',
                    hintStyle: TextStyle(color: t.textMuted.withAlpha(140), fontSize: 13),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: t.textMuted),
                    filled: true,
                    fillColor: t.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // --- GAMES LIST ---
              // ==========================================
              ...games.map((game) {
                final coverUrl = game.displayCoverUrl;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.cardBorder),
                    boxShadow: DuwaTheme.cozyShadow,
                  ),
                  child: Row(
                    children: [
                      // Game Art Banner / Capsule
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 52,
                          decoration: BoxDecoration(
                            color: t.surfaceHighest,
                          ),
                          child: coverUrl != null && coverUrl.isNotEmpty
                              ? Image.network(
                                  coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(game.emoji, style: const TextStyle(fontSize: 22)),
                                  ),
                                )
                              : Center(
                                  child: Text(game.emoji, style: const TextStyle(fontSize: 22)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Playtime
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (game.playtimeHours > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.surfaceHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${game.playtimeHours}h played',
                                      style: TextStyle(
                                        color: t.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    game.genre,
                                    style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nominate Action
                      BouncyTap(
                        onTap: () => _nominateGame(game),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: t.surfaceHighest,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: t.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.plus, size: 14, color: t.primaryAccent),
                              const SizedBox(width: 5),
                              Text(
                                'Nominate',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
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
      },
    );
  }
}
