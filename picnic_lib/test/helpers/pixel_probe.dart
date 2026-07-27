import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 위젯 서브트리를 논리 픽셀 1:1 로 뜬 비트맵.
///
/// 골든이 못 잡는 건 "왜" 다. 픽셀을 직접 읽으면 어떤 위젯 종류를 썼는지와
/// 무관하게 "여백에 카드 배경이 보이는가", "블록이 실제로 칠해지는가" 를
/// 그대로 물을 수 있다. 금지 위젯 목록을 늘리는 방식은 우회 방법도 같이 늘어난다.
///
/// 스켈레톤/셔머 회귀에 특히 필요하다. [Shimmer] 는 자식을 `BlendMode.srcIn`
/// ShaderMask 로 덮으므로, Shimmer 안에 불투명 배경이 하나라도 있으면 그 위의
/// 블록이 전부 같은 그라디언트로 뭉개져 구조 없는 회색 덩어리가 된다. 위젯
/// 트리만 보는 단언으로는 `Material(color: ...)`, 1px 들여놓은 [ColoredBox],
/// 2x2 로 줄인 블록이 전부 초록으로 통과한다.
class PixelProbe {
  PixelProbe(this._rgba, this.width, this.height, this.origin);

  final Uint8List _rgba;
  final int width;
  final int height;

  /// 캡처 좌상단의 전역 좌표.
  final Offset origin;

  /// 전역 좌표 [global] 픽셀의 ARGB 16진 문자열.
  String at(Offset global) {
    final local = global - origin;
    final x = local.dx.floor();
    final y = local.dy.floor();
    expect(
      x >= 0 && x < width && y >= 0 && y < height,
      isTrue,
      reason: '$global 이 캡처(${width}x$height @ $origin) 밖이다',
    );
    final i = (y * width + x) * 4;
    return ((_rgba[i + 3] << 24) |
            (_rgba[i] << 16) |
            (_rgba[i + 1] << 8) |
            _rgba[i + 2])
        .toRadixString(16)
        .padLeft(8, '0');
  }

  /// [global] 사각형 안에서 [color] 가 **아닌** 픽셀의 비율.
  double fractionNot(Color color, Rect global) {
    final background = colorHex(color);
    var other = 0;
    var total = 0;
    for (var y = global.top.ceil(); y < global.bottom.floor(); y++) {
      for (var x = global.left.ceil(); x < global.right.floor(); x++) {
        total++;
        if (at(Offset(x.toDouble(), y.toDouble())) != background) other++;
      }
    }
    return other / total;
  }
}

/// [color] 의 ARGB 16진 문자열. [PixelProbe.at] 의 반환값과 같은 표기다.
String colorHex(Color color) => color.toARGB32().toRadixString(16).padLeft(8, '0');

/// [boundary] 가 가리키는 [RenderRepaintBoundary] 서브트리의 픽셀을 읽는다.
///
/// 경계는 테스트가 **명시적으로** 심은 [RepaintBoundary] 여야 한다. 그러지 않으면
/// 캡처 범위가 위로 올라가며 처음 만나는 repaint boundary(예: [ListView] 가 자식
/// 마다 붙이는 것)로 정해져, 호스트 위젯을 바꾸는 순간 조용히 달라진다.
Future<PixelProbe> capturePixels(WidgetTester tester, Finder boundary) async {
  final render = tester.renderObject<RenderRepaintBoundary>(boundary);
  final image = (await tester.runAsync(render.toImage))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final probe = PixelProbe(
    data.buffer.asUint8List(),
    image.width,
    image.height,
    tester.getRect(boundary).topLeft,
  );
  image.dispose();
  return probe;
}
