#!/bin/bash
# picnic_lib 테스트 실행 및 커버리지 측정
#
# 사용법:
#   ./scripts/run_tests.sh           # 전체 테스트 + 커버리지
#   ./scripts/run_tests.sh --no-cov  # 커버리지 없이 테스트만
#   ./scripts/run_tests.sh --html    # HTML 리포트 생성

set -e

# All integration callers must select local or dev explicitly. This script runs
# offline library tests only and never links or mutates a remote Supabase target.
if [ -n "${ENVIRONMENT:-}" ] && [ "$ENVIRONMENT" != "local" ] && [ "$ENVIRONMENT" != "dev" ]; then
  echo "NO-GO: production tests require the protected release workflow"
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$PROJECT_DIR/picnic_lib"
THRESHOLD=60
NO_COV=false
HTML_REPORT=false

# 인자 파싱
for arg in "$@"; do
  case $arg in
    --no-cov) NO_COV=true ;;
    --html) HTML_REPORT=true ;;
    --threshold=*) THRESHOLD="${arg#*=}" ;;
  esac
done

echo "=== picnic_lib 테스트 실행 ==="
cd "$LIB_DIR"

if [ "$NO_COV" = true ]; then
  flutter test
  echo "=== 테스트 완료 ==="
  exit 0
fi

# 테스트 실행 + 커버리지
flutter test --coverage

# lcov가 설치되어 있으면 필터링
if command -v lcov &> /dev/null; then
  echo "=== 생성 파일 제외한 커버리지 필터링 ==="
  lcov --remove coverage/lcov.info \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/generated/**' \
    -o coverage/lcov_filtered.info \
    --quiet

  # 커버리지 요약
  lcov --list coverage/lcov_filtered.info

  # HTML 리포트
  if [ "$HTML_REPORT" = true ] && command -v genhtml &> /dev/null; then
    genhtml coverage/lcov_filtered.info -o coverage/html --quiet
    echo "HTML report: coverage/html/index.html"
  fi

  # 임계값 검증
  COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
  echo ""
  echo "=== 커버리지: ${COVERAGE}% (임계값: ${THRESHOLD}%) ==="

  if [ -n "$COVERAGE" ] && (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "ERROR: 커버리지 ${COVERAGE}%가 임계값 ${THRESHOLD}% 미만입니다."
    exit 1
  fi
else
  echo "lcov가 설치되어 있지 않습니다. 'brew install lcov'로 설치하세요."
  echo "커버리지 파일: coverage/lcov.info"
fi

echo "=== 테스트 완료 ==="
