import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Frosted glass container using BackdropFilter.
/// Provides the Glassmorphism aesthetic: blur + semi-transparent tint + hairline border.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor ?? AppColors.glassTint,
            borderRadius: br,
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
