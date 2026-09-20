import 'package:flutter/material.dart';
import '../core/theme/duwa_colors.dart';
import '../core/theme/duwa_theme.dart';
import '../services/preferences_service.dart';

class ThemeViewModel extends ChangeNotifier {
  DuwaThemeVibe _currentVibe = DuwaThemeVibe.obsidianVoid;

  ThemeViewModel({DuwaThemeVibe? initialVibe}) {
    if (initialVibe != null) {
      _currentVibe = initialVibe;
    } else {
      _loadPersistedVibe();
    }
  }

  void _loadPersistedVibe() {
    final saved = PreferencesService().getThemeVibe();
    if (saved != null) {
      for (final vibe in DuwaThemeVibe.values) {
        if (vibe.name == saved) {
          _currentVibe = vibe;
          break;
        }
      }
    }
  }

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
    PreferencesService().setThemeVibe(vibe.name);
    notifyListeners();
  }

  void toggleVibe() {
    final next = (_currentVibe == DuwaThemeVibe.obsidianVoid)
        ? DuwaThemeVibe.cleanLight
        : DuwaThemeVibe.obsidianVoid;
    setVibe(next);
  }
}
