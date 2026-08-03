import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A reusable glassmorphism container: a blurred, translucent surface with a
/// hairline border. Used for the editor toolbars, side panels and the timeline
/// so the drawing canvas stays visible behind the chrome.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
    this.blur = 18,
    this.opacity,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double blur;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(AppTheme.radius);
    final double fill = opacity ?? (isDark ? 0.28 : 0.55);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkSurfaceHigh : Colors.white)
                .withValues(alpha: fill),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
