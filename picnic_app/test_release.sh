#!/bin/bash

set -e

# 🔧 설정값
BUILD_NAME="1.1.41"
BUILD_NUMBER="114113"
ENV="prod"

echo "📦 Flutter AAB 빌드 시작..."
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=ENVIRONMENT=$ENV

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ ! -f "$AAB_PATH" ]; then
  echo "❌ AAB 파일이 생성되지 않았습니다: $AAB_PATH"
  exit 1
fi

echo "✅ AAB 생성 완료: $AAB_PATH"

echo "🔍 AAB 내 .so 파일 포함 여부 확인..."
SO_COUNT=$(unzip -l $AAB_PATH | grep '\.so' | wc -l)
if [ "$SO_COUNT" -eq 0 ]; then
  echo "❌ .so 파일이 AAB에 포함되어 있지 않습니다. native dummy 소스 추가 필요"
  exit 1
fi

echo "✅ AAB 내 .so 파일 확인 완료 (${SO_COUNT}개)"

echo "🧹 Shorebird 캐시 정리"
shorebird cache clean

# echo "🚀 Shorebird 릴리스 테스트 시작..."
# shorebird release android \
#   --flutter-version=3.32.0 \
#   --dart-define=ENVIRONMENT=$ENV \
#   --build-name=$BUILD_NAME \
#   --build-number=$BUILD_NUMBER

# echo "✅ Shorebird 릴리스 명령 완료!"