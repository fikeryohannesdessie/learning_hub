import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool frosted;
  final double blur;
  final double opacity;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 1.0,
    this.borderRadius = 18,
    this.padding,
    this.margin,
    this.color,
    this.frosted = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius);

    final shadows = glowColor != null
        ? [
            BoxShadow(
              color: glowColor!.withOpacity(0.28),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ]
        : <BoxShadow>[];

    if (frosted) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            margin: margin,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
                width: 1.0,
              ),
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppTheme.kSurface,
        borderRadius: effectiveRadius,
        border: Border.all(color: AppTheme.kGlassBorder, width: 1.0),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
