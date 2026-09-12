import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';
import '../common/bouncy_tap.dart';

class DuwaNavRail extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCreatePressed;
  final int unreadNotificationsCount;
  final DuwaThemeData duwaTheme;

  const DuwaNavRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
    required this.unreadNotificationsCount,
    required this.duwaTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 860;
    final railWidth = isCompact ? 84.0 : 240.0;
    final isDark = !duwaTheme.isCleanLight;

    return Container(
      width: railWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F121A) : duwaTheme.surface,
        border: Border(
          right: BorderSide(
            color: isDark ? duwaTheme.cardBorder : duwaTheme.cardBorder,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // DUWA Brand Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 18),
              child: Row(
                mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: duwaTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: duwaTheme.primaryAccent.withAlpha(90),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DUWA',
                            style: TextStyle(
                              color: duwaTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Squad Gaming Hub',
                            style: TextStyle(
                              color: duwaTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan Session Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 16),
              child: BouncyTap(
                onTap: onCreatePressed,
                scaleDown: 0.94,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 11, horizontal: isCompact ? 0 : 12),
                  decoration: BoxDecoration(
                    gradient: duwaTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: duwaTheme.primaryAccent.withAlpha(100),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Plan Session',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
                children: [
                  _navItem(
                    index: 0,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    isCompact: isCompact,
                    badgeCount: unreadNotificationsCount,
                  ),
                  const SizedBox(height: 4),
                  _navItem(
                    index: 1,
                    label: 'Sessions',
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 4),
                  _navItem(
                    index: 2,
                    label: 'Squads',
                    icon: Icons.groups_outlined,
                    selectedIcon: Icons.groups_rounded,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 4),
                  _navItem(
                    index: 3,
                    label: 'You',
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ),

            // Bottom theme badge
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: isCompact
                  ? Text(
                      duwaTheme.vibeEmoji,
                      style: const TextStyle(fontSize: 18),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: duwaTheme.surfaceLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: duwaTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Text(duwaTheme.vibeEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              duwaTheme.vibeName,
                              style: TextStyle(
                                color: duwaTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool isCompact,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;

    return BouncyTap(
      onTap: () => onTabSelected(index),
      scaleDown: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 0 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? duwaTheme.primaryAccent.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: duwaTheme.primaryAccent.withAlpha(90), width: 1)
              : null,
        ),
        child: isCompact
            ? Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? duwaTheme.primaryAccent : duwaTheme.textMuted,
                    size: 24,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: 14,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: duwaTheme.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? duwaTheme.primaryAccent : duwaTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? duwaTheme.textPrimary : duwaTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: duwaTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
