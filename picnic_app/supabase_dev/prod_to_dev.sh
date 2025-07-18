#!/bin/bash

source ../scripts/project_ids.conf
source ../scripts/common_functions.sh

echo "프로덕션에서 개발 환경으로 복사를 시작합니다."

# 인자 파싱
components=$(parse_arguments "$@")

if [ -z "$components" ]; then
   log_message "오류: 유효한 인자가 제공되지 않았습니다."
   print_usage
    exit 1
fi

log_message "복사할 컴포넌트: $components"

read -s -p "프로덕션 데이터베이스 비밀번호: " PROD_DB_PASSWORD
echo
read -s -p "개발 데이터베이스 비밀번호: " DEV_DB_PASSWORD
echo


log_message "복사 실행 시작"
if execute_copy $PROD_PROJECT_ID $DEV_PROJECT_ID $PROD_DB_PASSWORD $DEV_DB_PASSWORD $components; then
   log_message "프로덕션에서 개발 환경으로의 복사가 완료되었습니다."
else
  log_message "오류: 프로덕션에서 개발 환경으로의 복사 중 문제가 발생했습니다."
    exit 1
fi