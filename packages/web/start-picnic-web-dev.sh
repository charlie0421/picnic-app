#!/bin/bash

# 현재 디렉토리 경로
CURRENT_DIR=$(dirname "$0")

# 피크닉 웹 프로젝트 경로
PROJECT_DIR="$CURRENT_DIR/picnic-web"

# 프로젝트 디렉토리로 이동
cd "$PROJECT_DIR" || {
    echo "피크닉 웹 프로젝트 디렉토리를 찾을 수 없습니다."
    exit 1
}

echo "피크닉 웹 개발 서버를 시작합니다..."

# 패키지가 설치되어 있는지 확인
if [ ! -d "node_modules" ]; then
    echo "npm 패키지를 설치합니다..."
    npm install
fi

# 환경 변수 파일이 있는지 확인
if [ ! -f ".env.local" ] && [ -f ".env.local.example" ]; then
    echo ".env.local 파일이 없습니다. 샘플을 복사합니다."
    cp .env.local.example .env.local
    echo "환경 변수를 적절히 설정해주세요."
fi

# 환경 변수 파일에 Supabase 설정이 있는지 확인
if [ -f ".env.local" ]; then
    if ! grep -q "NEXT_PUBLIC_SUPABASE_URL" ".env.local" || ! grep -q "NEXT_PUBLIC_SUPABASE_ANON_KEY" ".env.local"; then
        echo "경고: Supabase 환경 변수가 설정되지 않았습니다. .env.local 파일을 확인해주세요."
    fi
fi

# 이미지 폴더가 있는지 확인
if [ ! -d "public/images" ]; then
    echo "이미지 폴더를 생성합니다..."
    mkdir -p public/images
fi

# 기본 아바타 이미지가 없을 경우 알림
if [ ! -f "public/images/default-avatar.png" ]; then
    echo "경고: 기본 아바타 이미지가 없습니다. public/images/default-avatar.png 파일을 추가해주세요."
fi

# 개발 서버 시작
npm run dev 