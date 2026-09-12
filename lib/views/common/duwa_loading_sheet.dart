import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/duwa_theme.dart';

/// Highly polished shimmer loading bottom sheet for session operations.
class DuwaLoadingSheet extends StatelessWidget {
  final DuwaThemeData duwaTheme;
  final String title;
  final String message;

  const DuwaLoadingSheet({
    super.key,
    required this.duwaTheme,
    this.title = 'Preparing session details...',
    this.message = 'Syncing responses and squad votes',
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required DuwaThemeData duwaTheme,
    String title = 'Loading session...',
    String message = 'Syncing responses and squad votes',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: duwaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DuwaLoadingSheet(
        duwaTheme: duwaTheme,
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = duwaTheme;
    final isLight = t.isCleanLight;
    final baseColor = isLight ? const Color(0xFFE2E8F0) : t.surfaceHighest;
    final highlightColor = isLight ? const Color(0xFFF8FAFC) : t.surfaceLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header titles
            Text(
              title,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // Shimmer Card 1: Dominant hero card skeleton
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shimmer Card 2: Row of 3 items
            Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Shimmer Card 3: List tile skeleton
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action button skeleton
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
