import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../services/firebase_service.dart';
import 'duwa_buttons.dart';

/// Clean, arcade-style modal for entering a 6-character squad room code.
class JoinCodeDialog extends StatefulWidget {
  final DuwaThemeData duwaTheme;
  final Function(Map<String, dynamic> gameNightData) onJoined;

  const JoinCodeDialog({
    super.key,
    required this.duwaTheme,
    required this.onJoined,
  });

  static Future<void> show(
    BuildContext context, {
    required DuwaThemeData duwaTheme,
    required Function(Map<String, dynamic> gameNightData) onJoined,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => JoinCodeDialog(
        duwaTheme: duwaTheme,
        onJoined: onJoined,
      ),
    );
  }

  @override
  State<JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<JoinCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter a room code');
      return;
    }

    // Auto prepend DUWA- if user only typed the 4-char suffix
    String formattedCode = rawCode.toUpperCase();
    if (!formattedCode.startsWith('DUWA-')) {
      formattedCode = 'DUWA-$formattedCode';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final playerName = FirebaseService().currentUser?.displayName ?? 'Gamer';
    final result = await FirebaseService().joinGameNightByCode(
      roomCode: formattedCode,
      playerName: playerName,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pop(context);
      widget.onJoined(result);
    } else {
      setState(() {
        _errorMessage = 'Lobby not found! Check code with your host 🎮';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.primaryAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.vpn_key_rounded,
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
                        'Join with Room Code',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Enter the 6-character squad code',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: t.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Code input field
            Container(
              decoration: BoxDecoration(
                color: t.surfaceHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _errorMessage != null
                      ? DuwaColors.errorRed
                      : t.primaryAccent.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  hintText: 'DUWA-XXXX',
                  hintStyle: TextStyle(
                    color: t.textMuted.withAlpha(120),
                    letterSpacing: 3,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _handleJoin(),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: DuwaColors.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            DuwaButton(
              label: 'Join Squad Lobby',
              icon: Icons.login_rounded,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _handleJoin,
            ),
          ],
        ),
      ),
    );
  }
}
