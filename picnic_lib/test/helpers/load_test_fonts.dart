import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  // 패밀리 이름이 프로덕션과 같아야 한다. Pretendard 는 picnic_lib 의
  // 패키지 폰트라서 빌드된 앱의 FontManifest 에는
  // `packages/picnic_lib/Pretendard` 로 등록되고, 디자인 시스템도
  // `package: 'picnic_lib'` 로 그 이름을 요청한다. 여기서 맨
  // 'Pretendard' 로 등록하면 스타일과 매칭되지 않아 테스트가
  // 폴백 폰트로 측정된다 — 오버플로 측정이 전부 어긋난다.
  final loader = FontLoader('packages/picnic_lib/Pretendard')
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Regular.otf',
      ),
    )
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Bold.otf',
      ),
    );
  await loader.load();
}
