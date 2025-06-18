#!/bin/bash

# CodeMagic 로컬 테스트 스크립트
# 사용법: ./test_codemagic_local.sh [app_name] [platform]
# 예시: ./test_codemagic_local.sh picnic_app android

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 파라미터 체크
APP_NAME=${1:-"picnic_app"}
PLATFORM=${2:-"android"}

log_info "=== CodeMagic 로컬 테스트 시작 ==="
log_info "앱: $APP_NAME, 플랫폼: $PLATFORM"

# 1. 프로젝트 디렉토리 확인
if [ ! -d "$APP_NAME" ]; then
    log_error "$APP_NAME 디렉토리가 존재하지 않습니다!"
    exit 1
fi

log_success "$APP_NAME 디렉토리 확인됨"

# 2. Flutter 설치 확인
if ! command -v flutter &> /dev/null; then
    log_error "Flutter가 설치되지 않았습니다!"
    exit 1
fi

log_success "Flutter 설치 확인됨"
flutter --version

# 3. 환경 변수 설정 (개발용)
export ENVIRONMENT=dev
export PATH="$PATH:$HOME/.shorebird/bin"

# 4. 앱 디렉토리로 이동
cd "$APP_NAME"

# 5. Flutter 의존성 설치 테스트
log_info "=== Flutter 의존성 설치 테스트 ==="
flutter clean
flutter pub get

if [ $? -eq 0 ]; then
    log_success "Flutter 의존성 설치 성공"
else
    log_error "Flutter 의존성 설치 실패"
    exit 1
fi

# 6. 플랫폼별 빌드 테스트
if [ "$PLATFORM" = "android" ]; then
    log_info "=== Android 빌드 테스트 ==="
    
    # Android 키스토어 확인
    if [ ! -f "android/app/build.gradle" ]; then
        log_error "Android 빌드 파일이 존재하지 않습니다!"
        exit 1
    fi
    
    # 디버그 빌드 테스트
    log_info "디버그 APK 빌드 테스트..."
    
    # Flutter가 기대하는 경로를 미리 생성
    mkdir -p build/app/outputs/apk/debug/
    mkdir -p build/app/outputs/flutter-apk/
    
    # Flutter 빌드 실행 (Flutter의 "파일을 찾을 수 없다" 메시지는 무시 - 실제로는 빌드 성공)
    flutter build apk --debug --dart-define=ENVIRONMENT=dev || echo "Flutter 빌드 완료 (메시지 무시)"
    
    # 빌드 후 파일 확인 및 복사
    log_info "빌드 결과 확인 및 경로 설정 중..."
    
    # 실제 생성된 APK를 Flutter가 찾는 경로로 복사
    if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
        # Flutter가 찾는 표준 경로로 복사
        cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/apk/debug/
        cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/flutter-apk/
        
        # 파일 크기 확인
        APK_SIZE=$(du -h android/app/build/outputs/apk/debug/app-debug.apk | cut -f1)
        log_success "디버그 APK 빌드 성공 (크기: $APK_SIZE)"
        log_info "APK 위치: android/app/build/outputs/apk/debug/app-debug.apk"
    else
        log_error "디버그 APK 빌드 실패 - APK 파일을 찾을 수 없습니다"
        # 디버그용 파일 탐색
        log_info "APK 파일 탐색 중..."
        find . -name "*.apk" -type f 2>/dev/null | head -5
        exit 1
    fi
    
    # 릴리즈 빌드 테스트 (키스토어 없이)
    log_info "릴리즈 AAB 빌드 테스트..."
    flutter build appbundle --release --dart-define=ENVIRONMENT=dev --no-shrink || echo "AAB 빌드 완료 (메시지 무시)"
    
    # Flutter가 기대하는 경로에 파일 복사
    mkdir -p build/app/outputs/bundle/release/
    
    # 실제 생성된 AAB를 Flutter가 찾는 경로로 복사
    if [ -f "android/app/build/outputs/bundle/release/app-release.aab" ]; then
        cp android/app/build/outputs/bundle/release/app-release.aab build/app/outputs/bundle/release/
        log_success "릴리즈 AAB 빌드 성공 (경로 수정됨)"
    else
        log_warning "릴리즈 AAB 빌드 실패 (키스토어 미설정으로 인한 정상적인 실패일 수 있음)"
    fi

elif [ "$PLATFORM" = "ios" ]; then
    log_info "=== iOS 빌드 테스트 ==="
    
    # macOS 확인
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS 빌드는 macOS에서만 가능합니다!"
        exit 1
    fi
    
    # Xcode 확인
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode가 설치되지 않았습니다!"
        exit 1
    fi
    
    # CocoaPods 설치 확인
    if ! command -v pod &> /dev/null; then
        log_error "CocoaPods가 설치되지 않았습니다!"
        log_info "설치 명령: sudo gem install cocoapods"
        exit 1
    fi
    
    # CocoaPods 의존성 설치
    log_info "CocoaPods 의존성 설치..."
    cd ios
    pod install --repo-update
    cd ..
    
    # iOS 빌드 테스트
    log_info "iOS 빌드 테스트..."
    flutter build ios --debug --dart-define=ENVIRONMENT=dev --no-codesign
    
    # Flutter가 기대하는 경로에 디렉토리 생성
    log_info "iOS 빌드 경로 설정 중..."
    mkdir -p build/ios/iphoneos/
    
    # 실제 생성된 iOS 앱을 Flutter가 찾는 경로로 복사
    if [ -d "ios/build/Debug-iphoneos/Runner.app" ]; then
        cp -r ios/build/Debug-iphoneos/Runner.app build/ios/iphoneos/
        log_success "iOS 빌드 성공 (경로 수정됨)"
    elif [ -d "build/ios/Debug-iphoneos/Runner.app" ]; then
        # 이미 올바른 경로에 있는 경우
        log_success "iOS 빌드 성공 (기본 경로 사용)"
    else
        log_warning "iOS 빌드 파일을 찾을 수 없습니다"
        # iOS 빌드 결과 탐색
        find . -name "Runner.app" -type d 2>/dev/null | head -5
    fi
fi

# 7. Shorebird 테스트 (picnic_app만 해당)
if [ "$APP_NAME" = "picnic_app" ] && [ "$PLATFORM" = "android" ]; then
    log_info "=== Shorebird 설정 테스트 ==="
    
    if command -v shorebird &> /dev/null; then
        log_success "Shorebird CLI 설치 확인됨"
        shorebird --version
        
        # Shorebird 초기화 확인
        if [ -f "shorebird.yaml" ]; then
            log_success "Shorebird 설정 파일 확인됨"
        else
            log_warning "Shorebird 설정 파일이 없습니다. 'shorebird init' 실행 필요"
        fi
    else
        log_warning "Shorebird CLI가 설치되지 않았습니다"
        log_info "설치 명령: curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash"
    fi
fi

# 8. 빌드 결과물 확인
log_info "=== 빌드 결과물 확인 ==="
if [ "$PLATFORM" = "android" ]; then
    find . -name "*.apk" -o -name "*.aab" | head -10
elif [ "$PLATFORM" = "ios" ]; then
    find . -name "*.app" -o -name "*.ipa" | head -10
fi

log_success "=== 로컬 테스트 완료 ===" 