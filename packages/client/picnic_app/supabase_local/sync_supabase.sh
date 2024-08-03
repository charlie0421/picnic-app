#!/bin/bash

# 변수 설정
REMOTE_DB_HOST="db.xtijtefcycoeqludlngc.supabase.co"
REMOTE_DB_NAME="postgres"
REMOTE_DB_USER="postgres"
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="54322"
LOCAL_DB_NAME="postgres"
LOCAL_DB_USER="postgres"
DUMP_FILE="remote_dump.sql"
PROJECT_ID="xtijtefcycoeqludlngc"
LOCAL_SUPABASE_DIR="./supabase"

echo "Supabase 원격 데이터베이스와 Edge Function을 로컬로 가져오는 스크립트를 시작합니다."

# 원격 데이터베이스 비밀번호 입력
read -s -p "원격 데이터베이스 비밀번호를 입력하세요: " REMOTE_DB_PASSWORD
echo
export PGPASSWORD=$REMOTE_DB_PASSWORD

# 로컬 데이터베이스 비밀번호 입력
read -s -p "로컬 데이터베이스 비밀번호를 입력하세요 (기본값: postgres): " LOCAL_DB_PASSWORD
echo
LOCAL_DB_PASSWORD=${LOCAL_DB_PASSWORD:-postgres}

# 1. 원격 데이터베이스에서 덤프 생성
echo "원격 데이터베이스에서 덤프를 생성합니다..."
docker run --rm -v $(pwd)/$LOCAL_SUPABASE_DIR:/dumps -e PGPASSWORD=$REMOTE_DB_PASSWORD postgres pg_dump -h $REMOTE_DB_HOST -U $REMOTE_DB_USER -f /dumps/$DUMP_FILE $REMOTE_DB_NAME
if [ $? -ne 0 ]; then
    echo "덤프 생성에 실패했습니다. 스크립트를 종료합니다."
    exit 1
fi

# 환경 변수 재설정
export PGPASSWORD=$LOCAL_DB_PASSWORD

# 2. 로컬 데이터베이스의 public 스키마 초기화
echo "로컬 데이터베이스의 public 스키마를 초기화합니다..."
docker run --rm --network=host -e PGPASSWORD=$LOCAL_DB_PASSWORD postgres psql -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $LOCAL_DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
if [ $? -ne 0 ]; then
    echo "로컬 스키마 초기화에 실패했습니다. 스크립트를 종료합니다."
    exit 1
fi

# 3. 덤프 파일을 로컬 데이터베이스에 적용
echo "덤프 파일을 로컬 데이터베이스에 적용합니다..."
docker run --rm -v $(pwd)/$LOCAL_SUPABASE_DIR:/dumps --network=host -e PGPASSWORD=$LOCAL_DB_PASSWORD postgres psql -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $LOCAL_DB_NAME -f /dumps/$DUMP_FILE
if [ $? -ne 0 ]; then
    echo "덤프 파일 적용에 실패했습니다. 스크립트를 종료합니다."
    exit 1
fi

echo "데이터 가져오기가 완료되었습니다."

# 4. Edge Function 가져오기
echo "Edge Function을 가져옵니다..."

# 현재 디렉토리를 저장
CURRENT_DIR=$(pwd)

# Supabase 중지 및 재시작
echo "Supabase를 중지합니다..."
supabase stop
if [ $? -ne 0 ]; then
    echo "Supabase 중지에 실패했습니다."
    exit 1
fi

echo "Supabase를 시작합니다..."
supabase start
if [ $? -ne 0 ]; then
    echo "Supabase 시작에 실패했습니다."
    exit 1
fi

echo "스크립트 실행이 완료되었습니다."
