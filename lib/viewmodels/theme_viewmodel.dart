import 'package:flutter/material.dart';
import '../core/theme/duwa_colors.dart';
import '../core/theme/duwa_theme.dart';

class ThemeViewModel extends ChangeNotifier {
  DuwaThemeVibe _currentVibe = DuwaThemeVibe.obsidianVoid;

  DuwaThemeVibe get currentVibe => _currentVibe;

  bool get isDark => _currentVibe == DuwaThemeVibe.obsidianVoid;
  bool get isLight => _currentVibe == DuwaThemeVibe.cleanLight;
  bool get isObsidian => isDark;
  bool get isCleanLight => isLight;
  bool get isCozy => false;
  bool get isMysticOcean => false;
  bool get isBloom => false;

  DuwaThemeData get themeData => switch (_currentVibe) {
        DuwaThemeVibe.obsidianVoid => DuwaThemeData.obsidianVoid(),
        DuwaThemeVibe.cleanLight => DuwaThemeData.cleanLight(),
      };

  ThemeData get materialTheme => DuwaTheme.buildMaterialTheme(themeData);

  void setVibe(DuwaThemeVibe vibe) {
    if (_currentVibe == vibe) return;
    _currentVibe = vibe;
    notifyListeners();
  }

  void toggleVibe() {
    _currentVibe = (_currentVibe == DuwaThemeVibe.obsidianVoid)
        ? DuwaThemeVibe.cleanLight
        : DuwaThemeVibe.obsidianVoid;
    notifyListeners();
  }
}
