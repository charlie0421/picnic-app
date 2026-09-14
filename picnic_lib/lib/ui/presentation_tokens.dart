import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';

abstract final class PicnicUi {
  static const double minimumTapTarget = 48;
  static const double _actionContrastTarget = 4.8;

  static Color? _actionCacheKey;
  static Color? _actionCacheValue;
  static Color? _onActionCacheKey;
  static Color? _onActionCacheValue;
  static Color? _primaryForegroundCacheKey;
  static Color? _primaryForegroundCacheValue;
  static Color? _secondaryForegroundCacheKey;
  static Color? _secondaryForegroundCacheValue;

  static Color get surface => AppColors.grey00;
  static Color get border => AppColors.grey200;
  static Color get inputBorder => AppColors.grey500;
  static Color get disabledSurface => AppColors.grey200;
  static Color get ink => AppColors.grey800;
  static Color get secondaryText => AppColors.grey600;
  static Color get quietText => const Color(0xFF686970);

  static Color get actionColor {
    final configuredPrimary = AppColors.primary500;
    if (_actionCacheKey != configuredPrimary || _actionCacheValue == null) {
      _actionCacheKey = configuredPrimary;
      _actionCacheValue = _accessibleActionShade(configuredPrimary);
    }
    return _actionCacheValue!;
  }

  static Color get onActionColor {
    final background = actionColor;
    if (_onActionCacheKey != background || _onActionCacheValue == null) {
      _onActionCacheKey = background;
      _onActionCacheValue = foregroundFor(background);
    }
    return _onActionCacheValue!;
  }

  static Color get primaryForeground {
    final background = AppColors.primary500;
    if (_primaryForegroundCacheKey != background ||
        _primaryForegroundCacheValue == null) {
      _primaryForegroundCacheKey = background;
      _primaryForegroundCacheValue = foregroundFor(background);
    }
    return _primaryForegroundCacheValue!;
  }

  static Color get secondaryForeground {
    final background = AppColors.secondary500;
    if (_secondaryForegroundCacheKey != background ||
        _secondaryForegroundCacheValue == null) {
      _secondaryForegroundCacheKey = background;
      _secondaryForegroundCacheValue = foregroundFor(background);
    }
    return _secondaryForegroundCacheValue!;
  }

  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      color: color ?? ink,
      fontSize: size,
      fontFamily: 'Pretendard',
      package: 'picnic_lib',
      fontWeight: weight,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static double horizontal(double value) => value.w;
  static double vertical(double value) => value.h;

  static BoxDecoration surfaceDecoration({double radius = 16, Color? color}) {
    final opaqueColor = color == null
        ? surface
        : Color.alphaBlend(color, surface);
    return BoxDecoration(
      color: opaqueColor,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static Color foregroundFor(Color background) {
    final effectiveBackground = Color.alphaBlend(background, surface);
    final darkContrast = _contrastRatio(AppColors.grey900, effectiveBackground);
    final lightContrast = _contrastRatio(surface, effectiveBackground);
    return darkContrast >= lightContrast ? AppColors.grey900 : surface;
  }

  static Color _accessibleActionShade(Color configuredPrimary) {
    final primary = Color.alphaBlend(configuredPrimary, surface);
    if (_contrastRatio(primary, surface) >= _actionContrastTarget) {
      return primary;
    }

    var lightestPassing = AppColors.grey900;
    var passingPrimaryFraction = 0.0;
    var failingPrimaryFraction = 1.0;

    for (var index = 0; index < 24; index += 1) {
      final candidatePrimaryFraction =
          (passingPrimaryFraction + failingPrimaryFraction) / 2;
      final candidate = _blendWithBlack(primary, candidatePrimaryFraction);
      if (_contrastRatio(candidate, surface) >= _actionContrastTarget) {
        lightestPassing = candidate;
        passingPrimaryFraction = candidatePrimaryFraction;
      } else {
        failingPrimaryFraction = candidatePrimaryFraction;
      }
    }

    return lightestPassing;
  }

  static Color _blendWithBlack(Color color, double colorFraction) {
    final argb = color.toARGB32();
    final red = (argb >> 16) & 0xff;
    final green = (argb >> 8) & 0xff;
    final blue = argb & 0xff;
    return Color.fromARGB(
      0xff,
      (red * colorFraction).round(),
      (green * colorFraction).round(),
      (blue * colorFraction).round(),
    );
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
