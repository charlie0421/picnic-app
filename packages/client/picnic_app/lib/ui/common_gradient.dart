import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

const Gradient commonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.mint500, AppColors.primary500]);

const Gradient commonGradientReverse = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary500, AppColors.mint500]);

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
  color: AppColors.grey00.withOpacity(0.15),
  spreadRadius: 0,
  blurRadius: 4,
);
