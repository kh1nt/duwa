import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../services/preferences_service.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../common/add_game_sheet.dart';
import '../common/bouncy_tap.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../create/create_game_night_sheet.dart';
import 'steam_integration_view.dart';
import 'theme_selector_view.dart';

enum _GameTabFilter { all, addedByYou, favorites }

class ProfileView extends StatefulWidget {
  final ProfileViewModel profileVm;
  final ThemeViewModel themeVm;
  final GameNightViewModel gameNightVm;
  final GroupsViewModel? groupsVm;
  final void Function(GameModel? initialGame)? onPlanWithGame;

  const ProfileView({
    super.key,
    required this.profileVm,
    required this.themeVm,
    required this.gameNightVm,
    this.groupsVm,
    this.onPlanWithGame,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  _GameTabFilter _activeFilter = _GameTabFilter.all;

  void _showEditProfileDialog(
    BuildContext context,
    dynamic p,
    DuwaThemeData t,
  ) {
    final nameController = TextEditingController(text: p.displayName);
    final bioController = TextEditingController(text: p.bio);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Profile',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GAMER TAG',
                  style: TextStyle(
                    color: t.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: t.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: t.surfaceHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'BIO / STATUS',
                  style: TextStyle(
                    color: t.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: bioController,
                  style: TextStyle(color: t.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: t.surfaceHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: t.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primaryAccent,
                  foregroundColor: t.surfaceLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    widget.profileVm.updateAvatar(
                      displayName: newName,
                      handle:
                          '@${newName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}',
                      initials:
                          newName.length >= 2
                              ? newName.substring(0, 2).toUpperCase()
                              : newName.toUpperCase(),
                      bio: bioController.text.trim(),
                      avatarEmoji: p.avatarEmoji,
                    );
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.profileVm, widget.themeVm, widget.gameNightVm]),
      builder: (_, __) {
        final p = widget.profileVm.profile;
        final t = widget.themeVm.themeData;
        return Scaffold(
          appBar: AppBar(
            title: const Text('You'),
            actions: [
              IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThemeSelectorView(themeVm: widget.themeVm),
                      ),
                    ),
                icon: Icon(Icons.tune_rounded, color: t.textSecondary),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: [
              _identity(context, p, t),
              const SizedBox(height: 20),
              _label('YOUR MOMENTUM', t),
              const SizedBox(height: 10),
              _stats(p, t),
              const SizedBox(height: 26),

              // --- SQUAD GAMES & FAVORITES SHOWCASE ---
              _gamesShowcase(context, p, t),
              const SizedBox(height: 26),

              _label('CONNECTED ACCOUNTS & STORAGE', t),
              const SizedBox(height: 10),
              _steam(context, p, t),
              const SizedBox(height: 10),
              _cloudinaryStorage(context, t),
              const SizedBox(height: 26),

              _label('APP SETTINGS', t),
              const SizedBox(height: 10),
              _setting(
                context,
                Icons.palette_outlined,
                'Appearance',
                'Choose your theme (Obsidian Void, Clean Light, Mystic Ocean, Bloom)',
                t,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeSelectorView(themeVm: widget.themeVm),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              _setting(
                context,
                Icons.notifications_active_outlined,
                'Notification Reminders',
                'Countdown alerts (2h, 15m), game voting ballots & push reminders',
                t,
                () => _showNotificationPreferencesSheet(context, t),
              ),

              const SizedBox(height: 8),
              _setting(
                context,
                Icons.logout_rounded,
                'Sign Out',
                'Switch account or log out of DUWA',
                t,
                () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          backgroundColor: t.surface,
                          title: Text(
                            'Sign Out',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: TextStyle(color: t.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: t.textMuted),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await FirebaseService().signOut();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _identity(BuildContext context, dynamic p, DuwaThemeData t) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: t.heroCardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.primaryAccent.withAlpha(55)),
        ),
        child: Row(
          children: [
            BouncyTap(
              onTap: () => _showAvatarPickerSheet(context, p, t),
              scaleDown: 0.92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.primaryAccent.withAlpha(40),
                      shape: BoxShape.circle,
                      border: Border.all(color: t.primaryAccent, width: 2),
                    ),
                    child: widget.profileVm.isUploadingAvatar
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(t.primaryAccent),
                            ),
                          )
                        : (p.photoUrl != null && p.photoUrl!.isNotEmpty
                            ? Image.network(
                                CloudinaryService().getOptimizedUrl(
                                  p.photoUrl!,
                                  width: 128,
                                  height: 128,
                                ),
                                fit: BoxFit.cover,
                                width: 64,
                                height: 64,
                                errorBuilder:
                                    (_, __, ___) => Text(
                                      p.avatarInitials,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: t.surfaceLowest,
                                      ),
                                    ),
                              )
                            : Text(
                                p.avatarInitials,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: t.surfaceLowest,
                                ),
                              )),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: t.primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.surface, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: t.primaryAccent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit gamer tag',
                        onPressed: () => _showEditProfileDialog(context, p, t),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.handle,
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _label(String value, DuwaThemeData t) => Text(
    value,
    style: TextStyle(
      color: t.primaryAccent,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );

  Widget _stats(dynamic p, DuwaThemeData t) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: t.cardBorder),
    ),
    child: Row(
      children: [
        _stat('${p.gameNightsHosted}', 'Hosted', t),
        _divider(t),
        _stat('${p.gameNightsPlayed}', 'Played', t),
        _divider(t),
        _stat('${p.favoriteGames.length}', 'Favorites', t),
      ],
    ),
  );

  Widget _stat(String value, String label, DuwaThemeData t) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: t.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _divider(DuwaThemeData t) =>
      Container(width: 1, height: 30, color: t.cardBorder);

  // ==========================================
  // --- SQUAD GAMES & FAVORITES SHOWCASE ---
  // ==========================================

  Widget _gamesShowcase(BuildContext context, dynamic p, DuwaThemeData t) {
    final catalog = widget.gameNightVm.catalogGames;
    final userUid = p.id as String;
    final favoriteList = List<String>.from(p.favoriteGames ?? []);

    final myAddedGames = catalog.where((g) {
      if (g.createdBy != null && g.createdBy == userUid) return true;
      if (g.imageUrl != null && g.imageUrl!.isNotEmpty) return true;
      return false;
    }).toList();

    final favoritedGames = catalog.where((g) {
      return favoriteList.contains(g.title);
    }).toList();

    List<GameModel> displayedGames;
    switch (_activeFilter) {
      case _GameTabFilter.all:
        displayedGames = catalog;
        break;
      case _GameTabFilter.addedByYou:
        displayedGames = myAddedGames;
        break;
      case _GameTabFilter.favorites:
        displayedGames = favoritedGames;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('SQUAD LIBRARY & FAVORITES', t),
            BouncyTap(
              onTap: () async {
                final added = await AddGameSheet.show(
                  context,
                  gameNightVm: widget.gameNightVm,
                  duwaTheme: t,
                );
                if (added != null) {
                  setState(() => _activeFilter = _GameTabFilter.addedByYou);
                }
              },
              scaleDown: 0.94,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: t.primaryAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.primaryAccent.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: t.primaryAccent, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'Add Game',
                      style: TextStyle(
                        color: t.primaryAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                label: 'All Games (${catalog.length})',
                isSelected: _activeFilter == _GameTabFilter.all,
                t: t,
                onTap: () => setState(() => _activeFilter = _GameTabFilter.all),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Added by You (${myAddedGames.length})',
                isSelected: _activeFilter == _GameTabFilter.addedByYou,
                t: t,
                onTap: () => setState(() => _activeFilter = _GameTabFilter.addedByYou),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Favorites (${favoritedGames.length})',
                isSelected: _activeFilter == _GameTabFilter.favorites,
                t: t,
                onTap: () => setState(() => _activeFilter = _GameTabFilter.favorites),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Games List
        if (displayedGames.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.cardBorder),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.gamepad2, color: t.textMuted, size: 28),
                const SizedBox(height: 8),
                Text(
                  _activeFilter == _GameTabFilter.addedByYou
                      ? 'No custom games added yet.'
                      : (_activeFilter == _GameTabFilter.favorites
                          ? 'No favorites starred yet. Tap the heart on any game!'
                          : 'No games found in catalog.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                ),
                if (_activeFilter == _GameTabFilter.addedByYou) ...[
                  const SizedBox(height: 12),
                  BouncyTap(
                    onTap: () => AddGameSheet.show(
                      context,
                      gameNightVm: widget.gameNightVm,
                      duwaTheme: t,
                    ),
                    scaleDown: 0.95,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.primaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+ Add Game with Cover Art',
                        style: TextStyle(
                          color: t.surfaceLowest,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedGames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final game = displayedGames[index];
              final isFav = favoriteList.contains(game.title);
              final isMine = (game.createdBy != null && game.createdBy == userUid) ||
                  (game.imageUrl != null && game.imageUrl!.isNotEmpty);
              final coverUrl = game.optimizedCoverUrl(width: 140, height: 100);

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Row(
                  children: [
                    // Cover Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: coverUrl != null
                          ? Image.network(
                              coverUrl,
                              width: 58,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverFallback(game, t),
                            )
                          : _coverFallback(game, t),
                    ),
                    const SizedBox(width: 12),

                    // Game Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isMine)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.primaryAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Added',
                                    style: TextStyle(
                                      color: t.primaryAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${game.playerCountRecommendation} · ${game.genre}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions: Favorite + Plan Session
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? Colors.redAccent : t.textMuted,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.profileVm.toggleFavoriteGame(game.title);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                        ),
                        BouncyTap(
                          onTap: () {
                            if (widget.onPlanWithGame != null) {
                              widget.onPlanWithGame!(game);
                            } else {
                              final effectiveGroups = widget.groupsVm ?? GroupsViewModel();
                              CreateGameNightSheet.show(
                                context,
                                gameNightVm: widget.gameNightVm,
                                groupsVm: effectiveGroups,
                                duwaTheme: t,
                                initialGame: game,
                                onGameNightConfirmed: () {},
                              );
                            }
                          },
                          scaleDown: 0.92,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: t.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: t.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded, color: t.primaryAccent, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  'Plan',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _coverFallback(GameModel game, DuwaThemeData t) {
    return Container(
      width: 58,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [game.startColor, game.endColor],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        game.emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required DuwaThemeData t,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? t.primaryAccent.withAlpha(35) : t.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? t.primaryAccent : t.cardBorder,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? t.primaryAccent : t.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- AVATAR PICKER SHEET ---
  // ==========================================

  Future<void> _handleAvatarUpload(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked != null) {
      widget.profileVm.setUploadingAvatar(true);
      final bytes = await picked.readAsBytes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading avatar to Cloudinary... ☁️'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final url = await CloudinaryService().uploadImageBytes(
        bytes: bytes,
        filename: picked.name.isNotEmpty ? picked.name : 'avatar.jpg',
        folder: 'duwa/avatars',
      );

      widget.profileVm.setUploadingAvatar(false);
      if (!context.mounted) return;

      if (url != null) {
        widget.profileVm.updatePhotoUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully! ✨'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final err = CloudinaryService().lastErrorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null && err.isNotEmpty
                  ? 'Cloudinary: $err'
                  : 'Cloudinary upload note: check preset in CloudinaryService',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAvatarPickerSheet(
    BuildContext context,
    dynamic p,
    DuwaThemeData t,
  ) {
    final emojis = [
      '🎮', '🍕', '🚀', '⚡', '👑', '🎧', '🔥', '🦊',
      '👾', '🎲', '🎯', '🐱', '🏆', '💎', '🛡️', '🕹️',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentEmoji = widget.profileVm.profile.avatarEmoji;
        final hasCustomPhoto = p.photoUrl != null && (p.photoUrl as String).isNotEmpty;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).padding.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: t.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Take Photo (Camera)
                BouncyTap(
                  onTap: () => _handleAvatarUpload(context, ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: t.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, color: t.primaryAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Take Photo (Camera)',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Cloudinary Photo Upload (Gallery)
                BouncyTap(
                  onTap: () => _handleAvatarUpload(context, ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: t.primaryAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.primaryAccent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.image, color: t.primaryAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Photo (Cloudinary)',
                          style: TextStyle(
                            color: t.primaryAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Remove Photo if active
                if (hasCustomPhoto) ...[
                  BouncyTap(
                    onTap: () {
                      widget.profileVm.updatePhotoUrl('');
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Remove Photo',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. Monogram gamer initials
                BouncyTap(
                  onTap: () {
                    widget.profileVm.updatePhotoUrl('');
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    decoration: BoxDecoration(
                      color: t.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.user, color: t.textPrimary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Use Gamer Monogram (${p.avatarInitials})',
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
                const SizedBox(height: 18),
                Text(
                  'OR CHOOSE BADGE',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (_, i) {
                    final emoji = emojis[i];
                    final isSelected = currentEmoji == emoji;
                    return BouncyTap(
                      scaleDown: 0.92,
                      onTap: () {
                        widget.profileVm.updateAvatar(
                          displayName: p.displayName,
                          handle: p.handle,
                          initials: p.avatarInitials,
                          bio: p.bio,
                          avatarEmoji: emoji,
                        );
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.primaryAccent.withAlpha(40)
                              : t.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? t.primaryAccent : t.cardBorder,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // --- CLOUDINARY MEDIA SETTINGS DRAWER ---
  // ==========================================

  Widget _cloudinaryStorage(BuildContext context, DuwaThemeData t) {
    final activeCloud = CloudinaryService().cloudName;
    return _setting(
      context,
      LucideIcons.cloud,
      'Media Storage (Cloudinary)',
      'Cloud: $activeCloud · Fast responsive CDN',
      t,
      () => _showCloudinarySettingsSheet(context, t),
    );
  }

  void _showCloudinarySettingsSheet(BuildContext context, DuwaThemeData t) {
    final cloudController = TextEditingController(text: CloudinaryService().cloudName);
    final presetController = TextEditingController(text: CloudinaryService().uploadPreset);
    bool isTesting = false;
    String? testResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: t.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.primaryAccent.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.cloud, color: t.primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cloudinary Storage',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: t.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'DUWA uses Cloudinary unsigned uploads for avatars and custom game box art, with automatic WebP/AVIF compression.',
                  style: TextStyle(color: t.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Status Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00F59B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pipeline Active (${CloudinaryService().cloudName})',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Credentials Inputs
                Text(
                  'CLOUD NAME',
                  style: TextStyle(
                    color: t.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: cloudController,
                  style: TextStyle(color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. dz4x2mmzc',
                    filled: true,
                    fillColor: t.surfaceHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'UNSIGNED UPLOAD PRESET',
                  style: TextStyle(
                    color: t.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: presetController,
                  style: TextStyle(color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. duwa_preset',
                    filled: true,
                    fillColor: t.surfaceHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (testResult != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: testResult!.contains('Success')
                          ? const Color(0xFF00F59B).withAlpha(25)
                          : Colors.redAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: testResult!.contains('Success')
                            ? const Color(0xFF00F59B)
                            : Colors.redAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testResult!.contains('Success')
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: testResult!.contains('Success')
                              ? const Color(0xFF00F59B)
                              : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.primaryAccent,
                          side: BorderSide(color: t.primaryAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: isTesting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: t.primaryAccent,
                                ),
                              )
                            : const Icon(Icons.speed_rounded, size: 16),
                        label: Text(isTesting ? 'Testing...' : 'Test Upload'),
                        onPressed: isTesting
                            ? null
                            : () async {
                                setModalState(() {
                                  isTesting = true;
                                  testResult = null;
                                });
                                CloudinaryService().configure(
                                  cloudName: cloudController.text.trim(),
                                  uploadPreset: presetController.text.trim(),
                                );
                                final ok = await CloudinaryService().testConnection();
                                setModalState(() {
                                  isTesting = false;
                                  if (ok) {
                                    testResult = 'Success! Cloudinary is working perfectly. ☁️✨';
                                  } else {
                                    final err = CloudinaryService().lastErrorMessage;
                                    testResult = err ?? 'Connection failed. Check cloud name and preset.';
                                  }
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.primaryAccent,
                          foregroundColor: t.surfaceLowest,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final cName = cloudController.text.trim();
                          final pName = presetController.text.trim();
                          CloudinaryService().configure(
                            cloudName: cName,
                            uploadPreset: pName,
                          );
                          PreferencesService().setCloudinaryCloudName(cName);
                          PreferencesService().setCloudinaryUploadPreset(pName);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cloudinary settings saved! ✨'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          setState(() {});
                        },
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      CloudinaryService().resetToDefaults();
                      cloudController.text = CloudinaryService().cloudName;
                      presetController.text = CloudinaryService().uploadPreset;
                      setModalState(() {
                        testResult = 'Reset to default credentials.';
                      });
                      setState(() {});
                    },
                    child: Text(
                      'Reset to App Defaults',
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _steam(BuildContext context, dynamic p, DuwaThemeData t) => _setting(
    context,
    Icons.gamepad_rounded,
    p.isSteamConnected ? 'Steam connected' : 'Connect Steam',
    p.isSteamConnected
        ? '${p.steamGamesCount} games · ${p.steamPersonaName}'
        : 'See games your squad already owns',
    t,
    () => Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SteamIntegrationView(
              profileVm: widget.profileVm,
              gameNightVm: widget.gameNightVm,
              duwaTheme: t,
            ),
      ),
    ),
  );

  Widget _setting(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    DuwaThemeData t,
    VoidCallback tap,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: t.primaryAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted, size: 20),
          ],
        ),
      ),
    ),
  );

  void _showNotificationPreferencesSheet(
    BuildContext context,
    DuwaThemeData t,
  ) {
    final prefs = PreferencesService();
    bool pushEnabled = prefs.getPushNotificationsEnabled();
    bool reminder2h = prefs.getReminder2HoursEnabled();
    bool reminder15m = prefs.getReminder15MinsEnabled();
    bool votingReminder = prefs.getVotingReminderEnabled();
    bool isTesting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: t.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: t.textMuted.withAlpha(70),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: t.heroCardGradient,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: t.primaryAccent.withAlpha(60),
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: t.primaryAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification Reminders',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stay synced with game sessions & voting',
                                style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Global Push Master Switch Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.surfaceHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pushEnabled
                              ? t.primaryAccent.withAlpha(50)
                              : t.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Push Reminders',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'System notifications for upcoming game nights',
                                  style: TextStyle(
                                    color: t.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: pushEnabled,
                            activeColor: t.primaryAccent,
                            onChanged: (val) async {
                              HapticFeedback.lightImpact();
                              setModalState(() => pushEnabled = val);
                              await prefs.setPushNotificationsEnabled(val);
                              if (val) {
                                await NotificationService().requestPermissions();
                                await NotificationService().syncAllSessionReminders(
                                  sessions: widget.gameNightVm.upcomingSessions,
                                  currentUserId: widget.profileVm.profile.id,
                                  currentUserName:
                                      widget.profileVm.profile.displayName,
                                );
                              } else {
                                await NotificationService().cancelAll();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Granular Reminder Options (Animated Opacity when disabled)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: pushEnabled ? 1.0 : 0.45,
                      child: IgnorePointer(
                        ignoring: !pushEnabled,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.surfaceHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: t.cardBorder),
                          ),
                          child: Column(
                            children: [
                              // 2 Hours Before
                              _notificationToggleTile(
                                title: '2 Hours Before Session',
                                subtitle:
                                    'Warm up, grab snacks & verify game downloads',
                                value: reminder2h,
                                t: t,
                                onChanged: (val) async {
                                  HapticFeedback.lightImpact();
                                  setModalState(() => reminder2h = val);
                                  await prefs.setReminder2HoursEnabled(val);
                                  await NotificationService().syncAllSessionReminders(
                                    sessions:
                                        widget.gameNightVm.upcomingSessions,
                                    currentUserId: widget.profileVm.profile.id,
                                    currentUserName:
                                        widget.profileVm.profile.displayName,
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: t.cardBorder.withAlpha(60),
                              ),

                              // 15 Minutes Before
                              _notificationToggleTile(
                                title: '15 Minutes Countdown',
                                subtitle:
                                    'Final alert to hop into Discord or voice channel',
                                value: reminder15m,
                                t: t,
                                onChanged: (val) async {
                                  HapticFeedback.lightImpact();
                                  setModalState(() => reminder15m = val);
                                  await prefs.setReminder15MinsEnabled(val);
                                  await NotificationService().syncAllSessionReminders(
                                    sessions:
                                        widget.gameNightVm.upcomingSessions,
                                    currentUserId: widget.profileVm.profile.id,
                                    currentUserName:
                                        widget.profileVm.profile.displayName,
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: t.cardBorder.withAlpha(60),
                              ),

                              // Voting Ballots
                              _notificationToggleTile(
                                title: 'Game Voting Ballots',
                                subtitle:
                                    'Reminds you before game night vote closes',
                                value: votingReminder,
                                t: t,
                                onChanged: (val) async {
                                  HapticFeedback.lightImpact();
                                  setModalState(() => votingReminder = val);
                                  await prefs.setVotingReminderEnabled(val);
                                  await NotificationService().syncAllSessionReminders(
                                    sessions:
                                        widget.gameNightVm.upcomingSessions,
                                    currentUserId: widget.profileVm.profile.id,
                                    currentUserName:
                                        widget.profileVm.profile.displayName,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Test Push Notification Button
                    BouncyTap(
                      onTap: () async {
                        if (isTesting) return;
                        HapticFeedback.mediumImpact();
                        setModalState(() => isTesting = true);

                        await NotificationService().requestPermissions();
                        final success =
                            await NotificationService().showTestNotification();

                        if (context.mounted) {
                          setModalState(() => isTesting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: t.surface,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: success
                                      ? t.secondaryAccent
                                      : Colors.redAccent,
                                ),
                              ),
                              content: Row(
                                children: [
                                  Icon(
                                    success
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    color: success
                                        ? t.secondaryAccent
                                        : Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      success
                                          ? '⚡ Test notification dispatched! Check your tray.'
                                          : 'Could not show test notification on this platform.',
                                      style: TextStyle(
                                        color: t.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: t.primaryAccent.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: t.primaryAccent.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isTesting)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    t.primaryAccent,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.bolt_rounded,
                                color: t.primaryAccent,
                                size: 18,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              isTesting
                                  ? 'Dispatching...'
                                  : 'Send Test Push Notification',
                              style: TextStyle(
                                color: t.primaryAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required DuwaThemeData t,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: t.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
