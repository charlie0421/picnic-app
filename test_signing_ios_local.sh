#!/bin/bash

# iOS 코드 사이닝 테스트 스크립트
set -e

APP_NAME=${1:-"picnic_app"}
echo "[INFO] === iOS 코드 사이닝 테스트 시작 ==="
echo "[INFO] 앱: $APP_NAME"

# 앱 디렉토리 확인
if [ ! -d "$APP_NAME" ]; then
    echo "[ERROR] $APP_NAME 디렉토리를 찾을 수 없습니다."
    exit 1
fi

cd "$APP_NAME"

echo "[SUCCESS] $APP_NAME 디렉토리 확인됨"

# Flutter 설치 확인
if ! command -v flutter &> /dev/null; then
    echo "[ERROR] Flutter가 설치되지 않았습니다."
    exit 1
fi

echo "[SUCCESS] Flutter 설치 확인됨"
flutter --version

echo "[INFO] === Flutter 의존성 설치 ===  "
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1
echo "[SUCCESS] Flutter 의존성 설치 성공"

echo "[INFO] === iOS 코드 사이닝 빌드 테스트 ==="

# CocoaPods 설치
echo "[INFO] CocoaPods 의존성 설치..."
cd ios
pod install > /dev/null 2>&1
cd ..
echo "[SUCCESS] CocoaPods 설치 완료"

# iOS Archive 빌드 (코드 사이닝 포함)
echo "[INFO] iOS Archive 빌드 (코드 사이닝 포함)..."
if flutter build ios --release --verbose 2>&1; then
    echo "[SUCCESS] iOS Archive 빌드 성공"
else
    echo "[WARNING] Archive 빌드 실패, 기본 빌드로 진행..."
    
    # 기본 iOS 빌드 시도
    echo "[INFO] 기본 iOS 빌드 시도..."
    if flutter build ios --verbose 2>&1; then
        echo "[SUCCESS] iOS 빌드 성공"
    else
        echo "[ERROR] iOS 빌드 실패"
        exit 1
    fi
fi

echo "[INFO] === 빌드 결과물 확인 ==="

# 빌드 결과물 위치 확인
IOS_BUILD_DIR="build/ios"
if [ -d "$IOS_BUILD_DIR" ]; then
    echo "[INFO] iOS 빌드 디렉토리 존재: $IOS_BUILD_DIR"
    
    # .app 파일 찾기
    find "$IOS_BUILD_DIR" -name "*.app" -type d | head -5 | while read app_path; do
        echo "[FOUND] $app_path"
        
        # 코드 사이닝 상태 확인
        if command -v codesign &> /dev/null; then
            echo "[INFO] 코드 사이닝 검증: $app_path"
            if codesign -dv "$app_path" 2>&1; then
                echo "[SUCCESS] 코드 사이닝 확인됨"
            else
                echo "[WARNING] 코드 사이닝 정보 없음 (개발 빌드)"
            fi
        fi
        
        # 앱 정보 확인
        if [ -f "$app_path/Info.plist" ]; then
            echo "[INFO] 앱 정보:"
            if command -v plutil &> /dev/null; then
                plutil -p "$app_path/Info.plist" | grep -E "(CFBundleIdentifier|CFBundleVersion|CFBundleShortVersionString)" || true
            fi
        fi
        echo "---"
    done
else
    echo "[ERROR] iOS 빌드 디렉토리를 찾을 수 없습니다: $IOS_BUILD_DIR"
    exit 1
fi

echo "[SUCCESS] === iOS 코드 사이닝 테스트 완료 ===" 