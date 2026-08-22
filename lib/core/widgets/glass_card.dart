import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xB31C2026), // 0.7 opacity
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: SoviColors.outline.withOpacity(0.15),
              width: 1,
            ),
      ),
      child: child,
    );

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: content,
      ),
    );

    if (margin != null) {
      glass = Padding(padding: margin!, child: glass);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: glass,
      );
    }

    return glass;
  }
}
