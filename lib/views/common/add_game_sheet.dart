import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_model.dart';
import '../../services/cloudinary_service.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import 'bouncy_tap.dart';
import 'duwa_buttons.dart';

/// Bottom sheet allowing squad members to add custom games to the DUWA catalog,
/// complete with cover photo upload via Cloudinary, emoji badges, and player count recommendations.
class AddGameSheet extends StatefulWidget {
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;
  final ValueChanged<GameModel>? onGameAdded;

  const AddGameSheet({
    super.key,
    required this.gameNightVm,
    required this.duwaTheme,
    this.onGameAdded,
  });

  static Future<GameModel?> show(
    BuildContext context, {
    required GameNightViewModel gameNightVm,
    required DuwaThemeData duwaTheme,
    ValueChanged<GameModel>? onGameAdded,
  }) {
    return showModalBottomSheet<GameModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddGameSheet(
        gameNightVm: gameNightVm,
        duwaTheme: duwaTheme,
        onGameAdded: onGameAdded,
      ),
    );
  }

  @override
  State<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends State<AddGameSheet> {
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _playersController = TextEditingController();

  String _selectedEmoji = '🎮';
  String? _uploadedImageUrl;
  Uint8List? _previewBytes;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  static const _emojis = [
    '🎮', '🎲', '🕹️', '⚔️', '🚀', '👑',
    '🎯', '👾', '🏆', '🏎️', '🐉', '🧟',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _playersController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _isUploadingImage = true;
      });

      HapticFeedback.lightImpact();

      final url = await CloudinaryService().uploadImageBytes(
        bytes: bytes,
        filename: picked.name.isNotEmpty ? picked.name : 'game_cover.jpg',
        folder: 'duwa/games',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
        if (url != null) {
          _uploadedImageUrl = url;
        }
      });

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover art uploaded to Cloudinary! ☁️✨'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cloudinary note: Upload preset not configured yet, using dynamic theme art instead.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking or uploading game cover: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removeCover() {
    HapticFeedback.lightImpact();
    setState(() {
      _uploadedImageUrl = null;
      _previewBytes = null;
    });
  }

  Future<void> _saveGame() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a game title')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final genre = _genreController.text.trim().isNotEmpty
        ? _genreController.text.trim()
        : 'Custom Game';

    final newGame = await widget.gameNightVm.createAndSaveCustomGame(
      title: title,
      genre: genre,
      emoji: _selectedEmoji,
      playerCount: _playersController.text.trim(),
      imageUrl: _uploadedImageUrl,
    );

    if (widget.onGameAdded != null) {
      widget.onGameAdded!(newGame);
    }

    if (mounted) {
      Navigator.pop(context, newGame);
    }
  }

  Widget _buildFieldLabel(String label, DuwaThemeData t) {
    return Text(
      label,
      style: TextStyle(
        color: t.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: t.cardBorder),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: t.primaryAccent.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: t.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Game to Library',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: t.textMuted,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Cover Art / Cloudinary Image Picker ---
              _buildFieldLabel('GAME COVER PHOTO (CLOUDINARY)', t),
              const SizedBox(height: 8),
              BouncyTap(
                onTap: _isUploadingImage ? null : _pickAndUploadCover,
                scaleDown: 0.98,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: t.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _previewBytes != null
                          ? t.primaryAccent.withAlpha(120)
                          : t.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_previewBytes != null)
                        Image.memory(
                          _previewBytes!,
                          fit: BoxFit.cover,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: t.primaryAccent,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload game box art or photo',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stored securely via Cloudinary CDN',
                              style: TextStyle(
                                color: t.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      if (_isUploadingImage)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      t.primaryAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Uploading cover... ☁️',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_previewBytes != null && !_isUploadingImage)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeCover,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Icon Emoji Badges ---
              _buildFieldLabel('GAME BADGE / EMOJI', t),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final e = _emojis[i];
                    final isSel = _selectedEmoji == e;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedEmoji = e);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel
                              ? t.primaryAccent.withAlpha(35)
                              : t.surfaceHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? t.primaryAccent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- Title Input ---
              _buildFieldLabel('TITLE', t),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: TextStyle(color: t.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Catan, Tekken 8, Helldivers 2',
                ),
              ),
              const SizedBox(height: 14),

              // --- Genre / Category ---
              _buildFieldLabel('GENRE / CATEGORY', t),
              const SizedBox(height: 6),
              TextField(
                controller: _genreController,
                style: TextStyle(color: t.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 4-Player Co-op, Board Game, Fighting',
                ),
              ),
              const SizedBox(height: 14),

              // --- Recommended Players ---
              _buildFieldLabel('RECOMMENDED PLAYERS', t),
              const SizedBox(height: 6),
              TextField(
                controller: _playersController,
                style: TextStyle(color: t.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 3-6 players (optional)',
                ),
              ),
              const SizedBox(height: 22),

              // Save CTA
              DuwaButton(
                label: 'Add to Squad Library',
                icon: Icons.check_rounded,
                isFullWidth: true,
                isLoading: _isSaving,
                themeOverride: t,
                onPressed: _isSaving || _isUploadingImage ? null : _saveGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
