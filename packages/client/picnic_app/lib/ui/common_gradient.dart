import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

const Gradient commonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.Mint500, AppColors.Primary500]);

const Gradient voteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3B847), AppColors.Gray00]);

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
  color: AppColors.Gray00.withOpacity(0.15),
  spreadRadius: 0,
  blurRadius: 4,
);
