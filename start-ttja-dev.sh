#!/bin/bash

echo "TTJA 개발 환경을 시작합니다..."

# 현재 디렉토리 저장
ORIGINAL_DIR=$(pwd)

# Next.js 서버 (ttja_web) 실행
cd ttja_web
echo "TTJA 사이드바 서버를 시작합니다 (포트: 3002)..."
npm run dev &
TTJA_WEB_PID=$!
echo "TTJA 사이드바 서버가 시작되었습니다. (PID: $TTJA_WEB_PID)"

# 원래 디렉토리로 돌아가기
cd $ORIGINAL_DIR

# Flutter 웹 서버 (ttja_app) 실행
cd ttja_app
echo "TTJA Flutter 웹 앱을 시작합니다 (포트: 8080)..."
flutter run -d chrome --web-port=8080 &
TTJA_APP_PID=$!
echo "TTJA Flutter 웹 앱이 시작되었습니다. (PID: $TTJA_APP_PID)"

echo "-----------------------------------"
echo "모든 TTJA 관련 서버가 실행되었습니다."
echo "사이드바 서버: http://localhost:3002"
echo "Flutter 웹 앱: http://localhost:8080"
echo "-----------------------------------"
echo "종료하려면 Ctrl+C를 누르세요."

# 종료 시 모든 프로세스 종료
trap "echo '종료 중...'; kill $TTJA_WEB_PID $TTJA_APP_PID; echo '모든 프로세스가 종료되었습니다.'; exit" INT TERM EXIT

# 무한 대기
wait