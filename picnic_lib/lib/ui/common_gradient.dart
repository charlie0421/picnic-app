import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

Gradient commonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.secondary500, AppColors.primary500]);

Gradient commonGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.secondary500, AppColors.primary500]);

Gradient commonGradientReverse = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary500, AppColors.secondary500]);

const Gradient voteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3B847), AppColors.grey00]);

const Gradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3B847), Color(0xFFFFFFFF)]);

const Gradient silverGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA6A8AF), Color(0xFFFFFFFF)]);

const Gradient bronzeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA17C1E), Color(0xFFFFFFFF)]);

const Gradient switchThumbGradient = RadialGradient(
  colors: [
    Color(0xFFFFFFFF),
    Color(0xFFF9F9F9),
    Color(0xFFDCDCDC),
  ],
  stops: [0.0, 0.54, 1.0],
);

final switchBoxShadow = BoxShadow(
  blurStyle: BlurStyle.inner,
  color: AppColors.grey00.withValues(alpha: 0.15),
  spreadRadius: 0,
  blurRadius: 4,
);
