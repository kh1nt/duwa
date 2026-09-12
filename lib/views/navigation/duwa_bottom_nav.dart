import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../common/bouncy_tap.dart';

/// Ergonomic Bottom Navigation Bar
/// Grounded dock with crystal-clear active indicators, proper safe-area padding,
/// and an elevated center action button for effortless 1-thumb planning.
class DuwaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCreatePressed;
  final int unreadNotificationsCount;
  final DuwaThemeData duwaTheme;

  const DuwaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
    required this.unreadNotificationsCount,
    required this.duwaTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: duwaTheme.surface,
        border: Border(
          top: BorderSide(
            color: duwaTheme.cardBorder.withAlpha(140),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(duwaTheme.isDark ? 30 : 8),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Tab 0: Home
              Expanded(
                child: _navItem(
                  index: 0,
                  icon: Icons.cottage_outlined,
                  activeIcon: Icons.cottage_rounded,
                  label: 'Home',
                  badge: unreadNotificationsCount,
                ),
              ),
              // Tab 1: Sessions
              Expanded(
                child: _navItem(
                  index: 1,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                ),
              ),
              // Center Action Launcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: BouncyTap(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onCreatePressed();
                  },
                  scaleDown: 0.90,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: duwaTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: duwaTheme.primaryAccent.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              // Tab 2: Squads
              Expanded(
                child: _navItem(
                  index: 2,
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups_rounded,
                  label: 'Squads',
                ),
              ),
              // Tab 3: You
              Expanded(
                child: _navItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'You',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badge = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? duwaTheme.primaryAccent : duwaTheme.textMuted;

    return BouncyTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
      scaleDown: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? duwaTheme.primaryAccent.withAlpha(duwaTheme.isDark ? 28 : 18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: color,
                    size: 21,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: DuwaColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
