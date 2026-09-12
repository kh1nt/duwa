import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/duwa_theme.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firebase_service.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../common/bouncy_tap.dart';
import 'steam_integration_view.dart';
import 'theme_selector_view.dart';

class ProfileView extends StatelessWidget {
  final ProfileViewModel profileVm;
  final ThemeViewModel themeVm;
  final GameNightViewModel gameNightVm;

  const ProfileView({
    super.key,
    required this.profileVm,
    required this.themeVm,
    required this.gameNightVm,
  });

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
                    profileVm.updateAvatar(
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
      listenable: Listenable.merge([profileVm, themeVm]),
      builder: (_, __) {
        final p = profileVm.profile;
        final t = themeVm.themeData;
        return Scaffold(
          appBar: AppBar(
            title: const Text('You'),
            actions: [
              IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThemeSelectorView(themeVm: themeVm),
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
              _label('CONNECTED ACCOUNTS', t),
              const SizedBox(height: 10),
              _steam(context, p, t),
              const SizedBox(height: 12),
              _setting(
                context,
                Icons.palette_outlined,
                'Appearance',
                'Choose your theme (Obsidian Void, Clean Light, Mystic Ocean, Bloom)',
                t,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeSelectorView(themeVm: themeVm),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _setting(
                context,
                Icons.info_outline_rounded,
                'About DUWA',
                'Squad gaming made simple · Version 1.0.0',
                t,
                () => showAboutDialog(
                  context: context,
                  applicationName: 'DUWA',
                  applicationVersion: '1.0.0',
                ),
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
                    child:
                        p.photoUrl != null && p.photoUrl!.isNotEmpty
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
                            ),
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

  void _showAvatarPickerSheet(
    BuildContext context,
    dynamic p,
    DuwaThemeData t,
  ) {
    final emojis = [
      '🎮',
      '🍕',
      '🚀',
      '⚡',
      '👑',
      '🎧',
      '🔥',
      '🦊',
      '👾',
      '🎲',
      '🎯',
      '🐱',
      '🏆',
      '💎',
      '🛡️',
      '🕹️',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentEmoji = profileVm.profile.avatarEmoji;
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
                const SizedBox(height: 6),
                const SizedBox(height: 16),

                // 1. Cloudinary Photo Upload
                BouncyTap(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Uploading avatar to Cloudinary... ☁️',
                            ),
                          ),
                        );
                      }
                      final url = await CloudinaryService().uploadImageBytes(
                        bytes: bytes,
                        filename: picked.name,
                        folder: 'duwa/avatars',
                      );
                      if (!context.mounted) return;
                      if (url != null) {
                        profileVm.updatePhotoUrl(url);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Avatar updated successfully! ✨'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cloudinary upload note: check preset in CloudinaryService',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: t.primaryAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.primaryAccent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.camera,
                          color: t.primaryAccent,
                          size: 18,
                        ),
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

                // 2. Monogram gamer initials
                BouncyTap(
                  onTap: () {
                    profileVm.updatePhotoUrl('');
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 16,
                    ),
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
                        profileVm.updateAvatar(
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
                          color:
                              isSelected
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
              profileVm: profileVm,
              gameNightVm: gameNightVm,
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: t.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: t.primaryAccent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ),
    ),
  );
}
