#!/bin/bash

# Codemagic Shorebird 패치 트리거 스크립트
# 사용법: ./scripts/trigger_patch.sh [ios|android|both]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정 파일 경로
CONFIG_FILE="$HOME/.config/picnic/codemagic.env"

# 기본값
BRANCH="production"

# 함수: 설정 로드
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# 함수: 설정 저장
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
CODEMAGIC_API_TOKEN="$CODEMAGIC_API_TOKEN"
CODEMAGIC_APP_ID="$CODEMAGIC_APP_ID"
EOF
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}설정이 저장되었습니다: $CONFIG_FILE${NC}"
}

# 함수: 설정 확인
check_config() {
    if [ -z "$CODEMAGIC_API_TOKEN" ]; then
        echo -e "${YELLOW}CODEMAGIC_API_TOKEN이 설정되지 않았습니다.${NC}"
        echo -e "Codemagic 대시보드 > Teams > Personal Account > Integrations > Codemagic API 에서 토큰을 확인하세요."
        echo -n "API Token: "
        read -r CODEMAGIC_API_TOKEN
    fi

    if [ -z "$CODEMAGIC_APP_ID" ]; then
        echo -e "${YELLOW}CODEMAGIC_APP_ID가 설정되지 않았습니다.${NC}"
        echo -e "Codemagic 대시보드에서 앱 설정 > App ID를 확인하세요."
        echo -n "App ID: "
        read -r CODEMAGIC_APP_ID
    fi

    # 설정 저장 여부 확인
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -n "설정을 저장하시겠습니까? (y/n): "
        read -r save_answer
        if [ "$save_answer" = "y" ] || [ "$save_answer" = "Y" ]; then
            save_config
        fi
    fi
}

# 함수: 빌드 트리거
trigger_build() {
    local workflow_id=$1
    local workflow_name=$2

    echo -e "${BLUE}$workflow_name 패치 빌드 트리거 중...${NC}"

    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
        -d "{
            \"appId\": \"$CODEMAGIC_APP_ID\",
            \"workflowId\": \"$workflow_id\",
            \"branch\": \"$BRANCH\"
        }" \
        "https://api.codemagic.io/builds")

    # 응답 파싱
    build_id=$(echo "$response" | grep -o '"buildId":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$build_id" ]; then
        echo -e "${GREEN}$workflow_name 빌드가 시작되었습니다${NC}"
        echo -e "  Build ID: ${BLUE}$build_id${NC}"
        echo -e "  URL: ${BLUE}https://codemagic.io/app/$CODEMAGIC_APP_ID/build/$build_id${NC}"
        return 0
    else
        echo -e "${RED}$workflow_name 빌드 트리거 실패${NC}"
        echo -e "응답: $response"
        return 1
    fi
}

# 함수: git push 확인
check_git_push() {
    local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")

    if [ "$ahead" -gt 0 ]; then
        echo -e "${YELLOW}경고: 로컬에 푸시되지 않은 $ahead개의 커밋이 있습니다.${NC}"
        echo -n "먼저 git push를 하시겠습니까? (y/n): "
        read -r push_answer
        if [ "$push_answer" = "y" ] || [ "$push_answer" = "Y" ]; then
            echo -e "${BLUE}git push 실행 중...${NC}"
            git push
            echo -e "${GREEN}git push 완료${NC}"
        fi
    fi
}

# 함수: 사용법 출력
usage() {
    echo -e "${BLUE}Codemagic Shorebird 패치 트리거 스크립트${NC}"
    echo ""
    echo "사용법: $0 [옵션] [플랫폼]"
    echo ""
    echo "플랫폼:"
    echo "  ios      iOS 패치만 트리거"
    echo "  android  Android 패치만 트리거"
    echo "  both     iOS와 Android 패치 모두 트리거 (기본값)"
    echo ""
    echo "옵션:"
    echo "  -b, --branch <branch>  빌드할 브랜치 (기본: production)"
    echo "  -c, --config           설정 재입력"
    echo "  -h, --help             이 도움말 출력"
    echo ""
    echo "예시:"
    echo "  $0                     # 양쪽 플랫폼 패치 트리거"
    echo "  $0 ios                 # iOS 패치만 트리거"
    echo "  $0 android             # Android 패치만 트리거"
    echo "  $0 -b develop both     # develop 브랜치에서 양쪽 플랫폼 패치"
    echo ""
    echo "설정 파일: $CONFIG_FILE"
}

# 메인 로직
main() {
    local platform="both"
    local reconfig=false

    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -c|--config)
                reconfig=true
                shift
                ;;
            ios|android|both)
                platform="$1"
                shift
                ;;
            *)
                echo -e "${RED}알 수 없는 옵션: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Shorebird 패치 트리거${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""

    # 설정 로드
    load_config

    # 재설정 요청 시 기존 설정 삭제
    if [ "$reconfig" = true ]; then
        CODEMAGIC_API_TOKEN=""
        CODEMAGIC_APP_ID=""
    fi

    # 설정 확인
    check_config

    # Git push 확인
    check_git_push

    echo ""
    echo -e "플랫폼: ${GREEN}$platform${NC}"
    echo -e "브랜치: ${GREEN}$BRANCH${NC}"
    echo ""

    # 빌드 트리거
    local success=true

    case $platform in
        ios)
            trigger_build "picnic-app-patch-ios" "iOS" || success=false
            ;;
        android)
            trigger_build "picnic-app-patch-android" "Android" || success=false
            ;;
        both)
            trigger_build "picnic-app-patch-ios" "iOS" || success=false
            echo ""
            trigger_build "picnic-app-patch-android" "Android" || success=false
            ;;
    esac

    echo ""
    if [ "$success" = true ]; then
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}  패치 빌드가 시작되었습니다!${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
        echo -e "Codemagic 대시보드에서 빌드 상태를 확인하세요:"
        echo -e "${BLUE}https://codemagic.io/apps${NC}"
    else
        echo -e "${RED}======================================${NC}"
        echo -e "${RED}  일부 빌드 트리거에 실패했습니다${NC}"
        echo -e "${RED}======================================${NC}"
        exit 1
    fi
}

main "$@"
