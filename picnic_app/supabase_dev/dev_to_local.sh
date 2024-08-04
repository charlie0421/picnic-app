#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source ../scripts/project_ids.conf
source ../scripts/common_functions.sh

echo "개발 환경에서 로컬 환경으로 복사를 시작합니다."

# 인자 파싱
components=$(parse_arguments "$@")

if [ -z "$components" ]; then
    print_usage
    exit 1
fi

read -s -p "개발 데이터베이스 비밀번호: " DEV_DB_PASSWORD
echo
read -s -p "로컬 데이터베이스 비밀번호: " LOCAL_DB_PASSWORD
echo

execute_copy $DEV_PROJECT_ID $LOCAL_PROJECT_ID $DEV_DB_PASSWORD $LOCAL_DB_PASSWORD $components

echo "개발 환경에서 로컬 환경으로의 복사가 완료되었습니다."