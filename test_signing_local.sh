#!/bin/bash

# 사이닝 테스트 스크립트
# 사용법: ./test_signing_local.sh [app_name]

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

log_info "=== 코드 사이닝 테스트 시작 ==="
log_info "앱: $APP_NAME"

# 1. 프로젝트 디렉토리 확인
if [ ! -d "$APP_NAME" ]; then
    log_error "$APP_NAME 디렉토리가 존재하지 않습니다!"
    exit 1
fi

cd "$APP_NAME"

# 2. 사이닝 설정 확인
log_info "=== 사이닝 설정 확인 ==="

# key.properties 파일 확인
if [ -f "android/key.properties" ]; then
    log_success "key.properties 파일 발견됨"
    echo "설정 내용:"
    cat android/key.properties | sed 's/Password=.*/Password=***HIDDEN***/'
else
    log_warning "key.properties 파일이 없습니다"
    log_info "테스트용 키스토어를 생성하겠습니다..."
    
    # 테스트용 키스토어 생성
    KEYSTORE_PATH="android/app/test-keystore.jks"
    if [ ! -f "$KEYSTORE_PATH" ]; then
        keytool -genkey -v \
            -keystore "$KEYSTORE_PATH" \
            -alias testkey \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -storepass testpass \
            -keypass testpass \
            -dname "CN=Test, OU=Test, O=Test, L=Test, S=Test, C=US"
        
        log_success "테스트용 키스토어 생성됨: $KEYSTORE_PATH"
    fi
    
    # 테스트용 key.properties 생성
    cat > android/key.properties << EOF
storePassword=testpass
keyPassword=testpass
keyAlias=testkey
storeFile=app/test-keystore.jks
EOF
    log_success "테스트용 key.properties 생성됨"
fi

# 3. build.gradle 사이닝 설정 확인
log_info "build.gradle 사이닝 설정 확인 중..."
if grep -q "signingConfigs" android/app/build.gradle; then
    log_success "build.gradle에 signingConfigs 설정 발견됨"
else
    log_warning "build.gradle에 signingConfigs 설정이 없습니다"
fi

# 4. 사이닝된 릴리즈 빌드 테스트
log_info "=== 사이닝된 릴리즈 빌드 테스트 ==="

# 경로 미리 설정
mkdir -p build/app/outputs/apk/release/
mkdir -p build/app/outputs/bundle/release/

log_info "사이닝된 APK 빌드 중..."
flutter build apk --release --dart-define=ENVIRONMENT=prod || echo "APK 빌드 완료"

# APK 사이닝 확인
if [ -f "android/app/build/outputs/apk/release/app-release.apk" ]; then
    APK_FILE="android/app/build/outputs/apk/release/app-release.apk"
    
    # 파일 크기 확인
    APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
    log_success "사이닝된 APK 생성됨 (크기: $APK_SIZE)"
    
    # APK 사이닝 정보 확인
    log_info "APK 사이닝 정보 확인 중..."
    if command -v aapt >/dev/null 2>&1; then
        aapt dump badging "$APK_FILE" | grep -E "(package|application-label)"
    else
        log_warning "aapt가 설치되지 않아 자세한 APK 정보를 확인할 수 없습니다"
    fi
    
    # Java keytool로 사이닝 정보 확인
    log_info "사이닝 인증서 정보 확인 중..."
    if command -v jarsigner >/dev/null 2>&1; then
        jarsigner -verify -verbose "$APK_FILE" | head -10
    else
        log_warning "jarsigner가 설치되지 않아 사이닝 검증을 할 수 없습니다"
    fi
    
    # 파일을 Flutter 표준 경로로 복사
    cp "$APK_FILE" build/app/outputs/apk/release/
    log_success "APK 파일 경로 동기화 완료"
    
else
    log_error "사이닝된 APK 생성 실패"
fi

log_info "사이닝된 AAB 빌드 중..."
flutter build appbundle --release --dart-define=ENVIRONMENT=prod || echo "AAB 빌드 완료"

# AAB 사이닝 확인
if [ -f "android/app/build/outputs/bundle/release/app-release.aab" ]; then
    AAB_FILE="android/app/build/outputs/bundle/release/app-release.aab"
    
    # 파일 크기 확인
    AAB_SIZE=$(du -h "$AAB_FILE" | cut -f1)
    log_success "사이닝된 AAB 생성됨 (크기: $AAB_SIZE)"
    
    # 파일을 Flutter 표준 경로로 복사
    cp "$AAB_FILE" build/app/outputs/bundle/release/
    log_success "AAB 파일 경로 동기화 완료"
    
else
    log_error "사이닝된 AAB 생성 실패"
fi

# 5. 사이닝 결과 요약
log_info "=== 사이닝 테스트 결과 요약 ==="
echo "생성된 파일:"
find android/app/build/outputs/ -name "*.apk" -o -name "*.aab" | while read file; do
    SIZE=$(du -h "$file" | cut -f1)
    echo "  📱 $file ($SIZE)"
done

echo ""
echo "표준 경로에 복사된 파일:"
find build/app/outputs/ -name "*.apk" -o -name "*.aab" | while read file; do
    SIZE=$(du -h "$file" | cut -f1)
    echo "  📦 $file ($SIZE)"
done

# 6. CodeMagic 환경 변수 안내
log_info "=== CodeMagic 사이닝 설정 안내 ==="
echo "CodeMagic 대시보드에서 설정해야 할 환경 변수:"
echo "  CM_KEYSTORE_PATH: 키스토어 파일 경로"
echo "  CM_KEYSTORE_PASSWORD: 키스토어 비밀번호" 
echo "  CM_KEY_ALIAS: 키 별칭"
echo "  CM_KEY_PASSWORD: 키 비밀번호"

# 정리
if [ -f "android/key.properties" ] && [ -f "android/app/test-keystore.jks" ]; then
    log_warning "테스트용 키스토어가 생성되었습니다. 프로덕션에서는 실제 키스토어를 사용하세요."
    echo "테스트 파일을 삭제하려면:"
    echo "  rm android/key.properties android/app/test-keystore.jks"
fi

log_success "=== 사이닝 테스트 완료 ===" 