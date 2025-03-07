#!/bin/bash

echo "Picnic 개발 환경을 시작합니다..."

# 현재 디렉토리 저장
ORIGINAL_DIR=$(pwd)

# Next.js 서버 (picnic_web) 실행
cd picnic_web
echo "Picnic 사이드바 서버를 시작합니다 (포트: 3001)..."
npm run dev &
PICNIC_WEB_PID=$!
echo "Picnic 사이드바 서버가 시작되었습니다. (PID: $PICNIC_WEB_PID)"

# 원래 디렉토리로 돌아가기
cd $ORIGINAL_DIR

# Flutter 웹 서버 (picnic_app) 실행
cd picnic_app
echo "Picnic Flutter 웹 앱을 시작합니다 (포트: 8081)..."
flutter run -d chrome --web-port=8081 --dart-define=FLUTTER_WEB_USE_SKIA=false &
PICNIC_APP_PID=$!
echo "Picnic Flutter 웹 앱이 시작되었습니다. (PID: $PICNIC_APP_PID)"

echo "-----------------------------------"
echo "모든 Picnic 관련 서버가 실행되었습니다."
echo "사이드바 서버: http://localhost:3001"
echo "Flutter 웹 앱: http://localhost:8081"
echo "-----------------------------------"
echo "종료하려면 Ctrl+C를 누르세요."

# 종료 시 모든 프로세스 종료
trap "echo '종료 중...'; kill $PICNIC_WEB_PID $PICNIC_APP_PID; echo '모든 프로세스가 종료되었습니다.'; exit" INT TERM EXIT

# 무한 대기
wait