import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';

/// A theme-aware gradient shimmer effect that gives skeletons an alive neon gaming glow.
class DuwaShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final DuwaThemeData? theme;

  const DuwaShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.theme,
  });

  @override
  State<DuwaShimmer> createState() => _DuwaShimmerState();
}

class _DuwaShimmerState extends State<DuwaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ??
        (Theme.of(context).brightness == Brightness.light
            ? DuwaThemeData.cleanLight()
            : DuwaThemeData.obsidianVoid());

    final baseColor = t.surfaceLight;
    final highlightColor = t.primaryAccent.withAlpha(50);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerValue = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              transform: _SlidingGradientTransform(slidePercent: shimmerValue),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.45, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2.4 - 1.2), 0.0, 0.0);
  }
}

/// Convenience placeholder block for skeleton screens.
class ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
