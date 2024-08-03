#!/bin/bash

# 변수 설정
PROJECT_ID="xtijtefcycoeqludlngc"
LOCAL_SUPABASE_DIR="supabase_local"

echo "Supabase Edge Function을 로컬로 가져오는 스크립트를 시작합니다."

# supabase_local 디렉토리 생성 (이미 존재하지 않는 경우)
mkdir -p $LOCAL_SUPABASE_DIR

# 현재 디렉토리를 저장
CURRENT_DIR=$(pwd)

# LOCAL_SUPABASE_DIR로 이동
cd $LOCAL_SUPABASE_DIR

# Edge Function 목록 가져오기
echo "Edge Function 목록을 가져오는 중..."
FUNCTIONS=$(supabase functions list --project-ref $PROJECT_ID)

if [ $? -ne 0 ]; then
    echo "Edge Function 목록을 가져오는데 실패했습니다."
    exit 1
fi

echo "가져온 Edge Function 목록:"
echo "$FUNCTIONS"

# ANSI 색상 코드 제거, 테이블 형식 처리, 함수 이름 추출 (SLUG 열), 그리고 상단 두 줄 제거
FUNCTION_NAMES=$(echo "$FUNCTIONS" |
    sed 's/\x1b\[[0-9;]*m//g' |
    sed '1,2d' |
    sed 's/│/|/g' |
    awk -F'|' '{print $3}' |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    sed '1,2d')

if [ -z "$FUNCTION_NAMES" ]; then
    echo "추출된 함수 이름이 없습니다. 스크립트를 종료합니다."
    exit 1
fi

echo "추출된 함수 이름:"
echo "$FUNCTION_NAMES"

# 각 Edge Function 다운로드
echo "$FUNCTION_NAMES" | while read -r func
do
    if [ -n "$func" ]; then
        echo "Downloading function: $func"
        supabase functions download "$func" --project-ref $PROJECT_ID
        if [ $? -ne 0 ]; then
            echo "Edge Function $func 가져오기에 실패했습니다."
            echo "오류 상세 정보:"
            supabase functions download "$func" --project-ref $PROJECT_ID --debug
        else
            echo "Edge Function $func를 성공적으로 가져왔습니다."
        fi
    fi
done

# 원래 디렉토리로 돌아가기
cd $CURRENT_DIR

echo "Edge Function 가져오기가 완료되었습니다."