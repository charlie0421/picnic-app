import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/ui/style.dart';

import 'host_app_asset_bundle.dart';
import 'test_environment.dart';

@immutable
final class PicnicUiTestPalette {
  const PicnicUiTestPalette({
    required this.primary,
    required this.secondary,
    required this.sub,
    required this.point,
    required this.point900,
  });

  final Color primary;
  final Color secondary;
  final Color sub;
  final Color point;
  final Color point900;

  factory PicnicUiTestPalette.fromProductionConfig(String hostAppDirectory) {
    final candidates = <File>[
      File('../$hostAppDirectory/config/prod.json'),
      File('$hostAppDirectory/config/prod.json'),
    ];
    final file = candidates.firstWhere(
      (candidate) => candidate.existsSync(),
      orElse: () => throw StateError(
        'Cannot find the production config for $hostAppDirectory',
      ),
    );
    final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final theme = config['theme'] as Map<String, dynamic>;
    final colors = theme['colors'] as Map<String, dynamic>;

    Color parse(String key) => Color(int.parse(colors[key] as String));

    return PicnicUiTestPalette(
      primary: parse('primary'),
      secondary: parse('secondary'),
      sub: parse('sub'),
      point: parse('point'),
      point900: parse('point_900'),
    );
  }
}

final class PicnicUiColorFixture {
  PicnicUiColorFixture._({
    required Color primary,
    required Color secondary,
    required Color sub,
    required Color point,
    required Color point900,
  }) : _primary = primary,
       _secondary = secondary,
       _sub = sub,
       _point = point,
       _point900 = point900;

  final Color _primary;
  final Color _secondary;
  final Color _sub;
  final Color _point;
  final Color _point900;
  bool _restored = false;

  /// Installs one brand palette without replacing Environment's initialized
  /// config, then restores every mutable AppColors value on [restore].
  static PicnicUiColorFixture install(PicnicUiTestPalette palette) {
    final fixture = PicnicUiColorFixture._(
      primary: AppColors.primary500,
      secondary: AppColors.secondary500,
      sub: AppColors.sub500,
      point: AppColors.point500,
      point900: AppColors.point900,
    );

    AppColors.primary500 = palette.primary;
    AppColors.secondary500 = palette.secondary;
    AppColors.sub500 = palette.sub;
    AppColors.point500 = palette.point;
    AppColors.point900 = palette.point900;
    return fixture;
  }

  void restore() {
    if (_restored) return;
    AppColors.primary500 = _primary;
    AppColors.secondary500 = _secondary;
    AppColors.sub500 = _sub;
    AppColors.point500 = _point;
    AppColors.point900 = _point900;
    _restored = true;
  }
}

void initPicnicUiTestEnvironment() {
  initTestColors();
}

/// Adds the two production Pretendard weights omitted by the legacy global
/// test-font helper without changing that helper for unrelated test suites.
Future<void> loadPicnicUiTestFontWeights() async {
  final loader = FontLoader('packages/picnic_lib/Pretendard')
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Medium.otf',
      ),
    )
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-SemiBold.otf',
      ),
    );
  await loader.load();
}

Widget buildPicnicUiTestApp(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
}) {
  return DefaultAssetBundle(
    bundle: hostAppAssetBundle,
    child: ScreenUtilInit(
      designSize: kAppDesignSize,
      minTextAdapt: true,
      splitScreenMode: kAppSplitScreenMode,
      child: MaterialApp(
        theme: theme,
        builder: (context, navigator) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, textScaler: textScaler),
          child: navigator!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}
