#!/usr/bin/env bash
#
# Local Shorebird OTA patch helper.
#
# 사용법:
#   ./scripts/shorebird-patch.sh <platform> [release-version]
#
#   <platform>          : ios | android | both
#   [release-version]   : 선택. 예: "1.2.27+122701".
#                         생략 시 pubspec.yaml 의 version 그대로 사용.
#                         Shorebird 에 등록된 release 와 정확히 일치해야 함.
#
# 환경 변수 (Sentry 디버그 심볼 업로드용 - 선택):
#   SENTRY_AUTH_TOKEN   - debug-files upload 권한 (project:releases) 필요
#   SENTRY_ORG          - default: icon-casting
#   SENTRY_PROJECT      - default: picnic-app
#
# 예시:
#   # 현재 prod release(=pubspec.yaml) 에 iOS+Android 패치 + Sentry 심볼 업로드
#   SENTRY_AUTH_TOKEN=sntry_... ./scripts/shorebird-patch.sh both
#
#   # 특정 release 에 Android 만 패치 (심볼 업로드 생략)
#   ./scripts/shorebird-patch.sh android 1.2.27+122701
#
# Codemagic 의 picnic-app-patch-* workflow 는 tag trigger 가 제거된 상태.
# 패치는 항상 이 스크립트(=로컬)로 진행.

set -euo pipefail

# ---- args ----
PLATFORM="${1:-}"
RELEASE_VERSION_OVERRIDE="${2:-}"

if [ -z "$PLATFORM" ]; then
  echo "Usage: $0 <ios|android|both> [release-version]"
  exit 1
fi

case "$PLATFORM" in
  ios|android|both) ;;
  *) echo "❌ Invalid platform: $PLATFORM (ios|android|both 중 하나)"; exit 1 ;;
esac

# ---- locate picnic_app dir ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

if [ ! -f pubspec.yaml ]; then
  echo "❌ pubspec.yaml 미발견: $APP_DIR"
  exit 1
fi

# ---- determine release version ----
if [ -n "$RELEASE_VERSION_OVERRIDE" ]; then
  RELEASE_VERSION="$RELEASE_VERSION_OVERRIDE"
else
  RELEASE_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version:[[:space:]]*//' | xargs)
fi

if [ -z "$RELEASE_VERSION" ]; then
  echo "❌ release version 결정 실패"
  exit 1
fi

# ---- locate shorebird CLI ----
SHOREBIRD="${SHOREBIRD:-$HOME/.shorebird/bin/shorebird}"
if [ ! -x "$SHOREBIRD" ]; then
  if command -v shorebird &>/dev/null; then
    SHOREBIRD=$(command -v shorebird)
  else
    echo "❌ shorebird CLI 미발견. https://docs.shorebird.dev 참고하여 설치"
    exit 1
  fi
fi

# ---- Sentry symbol upload helpers ----
sentry_upload_check() {
  if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
    echo "ℹ️ SENTRY_AUTH_TOKEN 미설정 — symbol 업로드 건너뜀"
    return 1
  fi
  if ! command -v sentry-cli &>/dev/null; then
    echo "ℹ️ sentry-cli 미설치 (brew install getsentry/tools/sentry-cli) — symbol 업로드 건너뜀"
    return 1
  fi
  return 0
}

sentry_upload_ios() {
  sentry_upload_check || return 0
  local org="${SENTRY_ORG:-icon-casting}"
  local project="${SENTRY_PROJECT:-picnic-app}"
  echo "📤 Sentry iOS 심볼 업로드..."
  local xcarchive
  xcarchive=$(find build/ios/archive -name "*.xcarchive" -type d 2>/dev/null | head -1 || true)
  if [ -n "$xcarchive" ] && [ -d "$xcarchive/dSYMs" ]; then
    sentry-cli debug-files upload --org "$org" --project "$project" \
      --include-sources "$xcarchive/dSYMs" 2>&1 || echo "⚠️ dSYM 업로드 실패 (무시)"
  fi
  if [ -d build/ios ]; then
    sentry-cli debug-files upload --org "$org" --project "$project" \
      --include-sources build/ios/ 2>&1 || echo "⚠️ Flutter Dart 심볼 업로드 실패 (무시)"
  fi
  echo "✅ Sentry iOS 심볼 업로드 단계 완료"
}

sentry_upload_android() {
  sentry_upload_check || return 0
  local org="${SENTRY_ORG:-icon-casting}"
  local project="${SENTRY_PROJECT:-picnic-app}"
  echo "📤 Sentry Android 심볼 업로드..."
  local native_libs
  native_libs=$(find build -path "*merged_native_libs*release*" -type d 2>/dev/null | head -1 || true)
  if [ -n "$native_libs" ]; then
    sentry-cli debug-files upload --org "$org" --project "$project" \
      "$native_libs" 2>&1 || echo "⚠️ native libs 업로드 실패 (무시)"
  fi
  if [ -d build/app ]; then
    sentry-cli debug-files upload --org "$org" --project "$project" \
      --include-sources build/app/ 2>&1 || echo "⚠️ Flutter Dart 심볼 업로드 실패 (무시)"
  fi
  echo "✅ Sentry Android 심볼 업로드 단계 완료"
}

# ---- platform-specific patch steps ----
patch_ios() {
  echo
  echo "════════════════════════════════════════"
  echo "🚀 shorebird patch ios"
  echo "════════════════════════════════════════"
  echo "📦 Flutter pub get..."
  flutter pub get
  echo "📦 CocoaPods install..."
  (cd ios && pod install)

  "$SHOREBIRD" patch ios \
    --release-version="$RELEASE_VERSION" \
    --no-confirm \
    --allow-native-diffs \
    --allow-asset-diffs \
    --dart-define=ENVIRONMENT=prod \
    -- --no-codesign

  echo "✅ iOS patch deploy 완료"
  sentry_upload_ios
}

patch_android() {
  echo
  echo "════════════════════════════════════════"
  echo "🚀 shorebird patch android"
  echo "════════════════════════════════════════"
  echo "📦 Flutter pub get..."
  flutter pub get

  "$SHOREBIRD" patch android \
    --release-version="$RELEASE_VERSION" \
    --no-confirm \
    --allow-native-diffs \
    --allow-asset-diffs \
    --dart-define=ENVIRONMENT=prod

  echo "✅ Android patch deploy 완료"
  sentry_upload_android
}

# ---- main ----
echo "🎯 Target release version: $RELEASE_VERSION"
echo "📱 Platform: $PLATFORM"
echo "📁 App dir: $APP_DIR"

case "$PLATFORM" in
  ios) patch_ios ;;
  android) patch_android ;;
  both) patch_ios; patch_android ;;
esac

echo
echo "🎉 모든 패치 단계 완료"
