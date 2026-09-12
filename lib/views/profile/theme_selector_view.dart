import 'package:flutter/material.dart';
import '../../core/theme/duwa_colors.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../common/duwa_cards.dart';

class ThemeSelectorView extends StatelessWidget {
  final ThemeViewModel themeVm;

  const ThemeSelectorView({
    super.key,
    required this.themeVm,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeVm,
      builder: (context, _) {
        final duwaTheme = themeVm.themeData;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Appearance'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your DUWA style',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: duwaTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch visual theme and typography to match your vibe.',
                  style: TextStyle(fontSize: 13, color: duwaTheme.textSecondary, height: 1.4),
                ),
                // THEME 1: OBSIDIAN DARK
                _buildThemeCard(
                  title: 'Obsidian Dark',
                  subtitle: 'Tactical deep charcoal canvas with Solar Flame & Ion Mint glow',
                  badgeText: 'DARK THEME',
                  emoji: '🌙',
                  vibe: DuwaThemeVibe.obsidianVoid,
                  isSelected: themeVm.isDark,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF141722), Color(0xFF0A0C10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: const Color(0xFFF8FAFC),
                  subtextColor: const Color(0xFF94A3B8),
                  colorSwatches: const [
                    DuwaColors.obsidianBackground,
                    DuwaColors.obsidianSurface,
                    DuwaColors.solarFlame,
                    DuwaColors.ionMint,
                    DuwaColors.hyperIndigo,
                  ],
                  onSelect: () => themeVm.setVibe(DuwaThemeVibe.obsidianVoid),
                ),
                const SizedBox(height: 18),

                // THEME 2: MINIMAL WHITE
                _buildThemeCard(
                  title: 'Minimal White',
                  subtitle: 'Crisp porcelain surface with deep black text & electric indigo',
                  badgeText: 'WHITE / LIGHT THEME',
                  emoji: '☀️',
                  vibe: DuwaThemeVibe.cleanLight,
                  isSelected: themeVm.isLight,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: const Color(0xFF09090B),
                  subtextColor: const Color(0xFF334155),
                  colorSwatches: const [
                    Color(0xFFF8FAFC),
                    Color(0xFFFFFFFF),
                    Color(0xFF09090B),
                    Color(0xFF4F46E5),
                    Color(0xFFFF5E1E),
                  ],
                  onSelect: () => themeVm.setVibe(DuwaThemeVibe.cleanLight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required String emoji,
    required DuwaThemeVibe vibe,
    required bool isSelected,
    required LinearGradient gradient,
    required Color textColor,
    required Color subtextColor,
    required List<Color> colorSwatches,
    required VoidCallback onSelect,
  }) {
    return DuwaCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      onTap: onSelect,
      gradient: gradient,
      border: Border.all(
        color: isSelected ? const Color(0xFF4F46E5) : (vibe == DuwaThemeVibe.cleanLight ? const Color(0xFFE2E8F0) : Colors.white.withAlpha(30)),
        width: isSelected ? 2.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: vibe == DuwaThemeVibe.cleanLight ? const Color(0xFF4F46E5).withAlpha(25) : Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: vibe == DuwaThemeVibe.cleanLight ? const Color(0xFF4F46E5) : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF4F46E5) : subtextColor.withAlpha(150),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: colorSwatches.map((color) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withAlpha(30), width: 1),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
