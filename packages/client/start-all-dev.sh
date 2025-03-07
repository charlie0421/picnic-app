#!/bin/bash

echo "모든 개발 환경을 시작합니다..."

# 현재 디렉토리 저장
ORIGINAL_DIR=$(pwd)

# Picnic 사이드바 서버 실행
cd packages/client/picnic_web
echo "Picnic 사이드바 서버를 시작합니다 (포트: 3001)..."
npm run dev &
PICNIC_WEB_PID=$!

# TTJA 사이드바 서버 실행
cd $ORIGINAL_DIR
cd packages/client/ttja_web
echo "TTJA 사이드바 서버를 시작합니다 (포트: 3002)..."
npm run dev &
TTJA_WEB_PID=$!

# Picnic Flutter 앱 실행
cd $ORIGINAL_DIR
cd packages/client/picnic_app
echo "Picnic Flutter 웹 앱을 시작합니다 (포트: 8081)..."
flutter run -d chrome --web-port=8081 &
PICNIC_APP_PID=$!

# TTJA Flutter 앱 실행
cd $ORIGINAL_DIR
cd packages/client/ttja_app
echo "TTJA Flutter 웹 앱을 시작합니다 (포트: 8080)..."
flutter run -d chrome --web-port=8080 &
TTJA_APP_PID=$!

echo "------------------------------------------"
echo "모든 서버가 실행되었습니다."
echo "Picnic 사이드바: http://localhost:3001"
echo "TTJA 사이드바: http://localhost:3002"
echo "Picnic Flutter 앱: http://localhost:8081"
echo "TTJA Flutter 앱: http://localhost:8080"
echo "------------------------------------------"
echo "종료하려면 Ctrl+C를 누르세요."

# 종료 시 모든 프로세스 종료
trap "echo '종료 중...'; kill $PICNIC_WEB_PID $TTJA_WEB_PID $PICNIC_APP_PID $TTJA_APP_PID; echo '모든 프로세스가 종료되었습니다.'; exit" INT TERM EXIT

# 무한 대기
wait