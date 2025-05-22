#!/bin/bash

# db-copy.sh
# Supabase 데이터베이스 복사 스크립트

PROD_DB_HOST="db.xtijtefcycoeqludlngc.supabase.co"
PROD_DB_PASSWORD="tkffudigksek1!"

DEV_DB_HOST="db.zrpvqycifrmtuoxtruip.supabase.co"
DEV_DB_PASSWORD="tkffudigksek1!"

# IP 주소 얻기
echo "🔍 데이터베이스 IP 주소 조회 중..."
PROD_DB_IP=$(dig +short $PROD_DB_HOST | head -n1)
DEV_DB_IP=$(dig +short $DEV_DB_HOST | head -n1)

echo "프로덕션 DB IP: $PROD_DB_IP"
echo "개발 DB IP: $DEV_DB_IP"

# 백업 파일 이름 (날짜 포함)
BACKUP_FILE="prod_dump_$(date +%Y%m%d_%H%M%S).sql"

echo "🚀 Supabase 데이터베이스 복사를 시작합니다..."

# 프로덕션 DB 덤프
echo "📤 프로덕션 DB 덤프 중..."
PGPASSWORD=$PROD_DB_PASSWORD pg_dump -h $PROD_DB_IP -U postgres -d postgres -F c -b -v -f $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ 프로덕션 DB 덤프 완료"
else
    echo "❌ 프로덕션 DB 덤프 실패"
    exit 1
fi

# 개발 DB 복원
echo "📥 개발 DB 복원 중..."
PGPASSWORD=$DEV_DB_PASSWORD pg_restore -h $DEV_DB_IP -U postgres -d postgres --clean --if-exists -v $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ 개발 DB 복원 완료"
else
    echo "❌ 개발 DB 복원 실패"
    exit 1
fi

echo "🎉 데이터베이스 복사가 완료되었습니다!"