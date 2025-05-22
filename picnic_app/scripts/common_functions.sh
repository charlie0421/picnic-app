#!/bin/bash
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}
# 인자 파싱 함수
parse_arguments() {
    local args=("$@")
    local result=()
    local all_flag=false
    for arg in "${args[@]}"; do
        case $arg in
            --all|-a) all_flag=true ;;
            --database|-d) result+=("database") ;;
            --storage|-s) result+=("storage") ;;
            --functions|-f) result+=("functions") ;;
            *) echo "Unknown argument: $arg"; exit 1 ;;
        esac
    done
    if [ "$all_flag" = true ]; then
        echo "database storage functions"
    else
        echo "${result[@]}"
    fi
}

# 데이터베이스 복사 함수
copy_database() {
    local source_project_id=$1
    local target_project_id=$2
    local source_db_password=$3
    local target_db_password=$4

    local source_db_host
    local source_db_port
    local source_db_user
    local target_db_host
    local target_db_port
    local target_db_user
    local dump_file="db_dump.sql"

    log_message "데이터베이스 복사 함수 시작"

    # 소스 프로젝트 호스트 , 포트, 유저 설정
    source_db_host="aws-0-ap-northeast-2.pooler.supabase.com"
    source_db_port="5432"
    source_db_name="postgres"
    source_db_user="postgres.$source_project_id"

    # 타겟 프로젝트 호스트 , 포트, 유저 설정
    if [ "$target_project_id" == "local" ]; then
        target_db_host="localhost"
        target_db_port="54322"
        target_db_name="postgres"
        target_db_user="postgres"
    else
        target_db_host="aws-0-ap-northeast-2.pooler.supabase.com"
        target_db_port="5432"
        target_db_name="postgres"
        target_db_user="postgres.$target_project_id"
    fi

    log_message "소스 HOST: $source_db_host"
    log_message "소스 PORT: $source_db_port"
    log_message "소스 User: $source_db_user"
    log_message "소스 DB: $source_db_name"
    log_message "타겟 HOST: $target_db_host"
    log_message "타겟 PORT: $target_db_port"
    log_message "타겟 User: $target_db_user"
    log_message "타겟 DB: $target_db_name"

    # 덤프 생성
    log_message "덤프 파일 생성 시작"
    log_message "Docker를 통한 pg_dump 실행"
    docker run --rm -v $(pwd):/dumps -e PGPASSWORD=$source_db_password postgres \
        pg_dump -h $source_db_host -p $source_db_port -U $source_db_user -d $source_db_name -f /dumps/$dump_file
    dump_result=$?

#    if [ "$source_project_id" == "local" ]; then
#        log_message "로컬 pg_dump 실행"
#        docker run --rm -v $(pwd):/dumps -e PGPASSWORD=$source_db_password postgres \
#            pg_dump -h $source_db_host -p $source_db_port -U $source_db_user -f /dumps/$dump_file
#            dump_result=$?
#    else
#        log_message "Docker를 통한 pg_dump 실행"
#        docker run --rm -v $(pwd):/dumps -e PGPASSWORD=$source_db_password postgres \
#            pg_dump -h $source_db_host -p $source_db_port -U source_db_user -d $db_name -f /dumps/$dump_file
#        dump_result=$?
#    fi

    if [ $dump_result -ne 0 ]; then
        log_message "덤프 생성 실패. 종료 코드: $dump_result"
        if [ -f $dump_file ]; then
          log_message "덤프 파일이 생성되었지만 오류가 발생했습니다."
        else
            log_message "덤프 파일이 생성되지 않았습니다."
        fi
        return 1
    fi

    log_message "덤프 파일 생성 완료"

# 타겟 데이터베이스 초기화
    log_message "타겟 데이터베이스 초기화 시작"
    if [ "$target_project_id" == "local" ]; then
        log_message "Docker를 통한 psql 실행 (로컬)"
        docker run --rm --network=host -e PGPASSWORD=$target_db_password postgres:14 \
            psql -h $target_db_host -p $target_db_port -U $target_db_user -d $target_db_name \
            -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
        init_result=$?
    else
        log_message "Docker를 통한 psql 실행"
        docker run --rm -e PGPASSWORD=$target_db_password postgres:14 \
            psql -h $target_db_host -p $target_db_port -U $target_db_user -d $target_db_name \
            -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
        init_result=$?
    fi

    if [ $init_result -ne 0 ]; then
        log_message "타겟 스키마 초기화 실패. 종료 코드: $init_result"
        return 1
    fi

    log_message "타겟 데이터베이스 초기화 완료"

    # 덤프 적용
    log_message "덤프 파일 적용 시작"
    docker run --rm -v $(pwd):/dumps --network=host -e PGPASSWORD=$target_db_password postgres:14 \
        psql -h $target_db_host -p $target_db_port -U $target_db_user -d $target_db_name -f /dumps/$dump_file
    apply_result=$?

    if [ $apply_result -ne 0 ]; then
        log_message "덤프 적용 실패. 종료 코드: $apply_result"
        return 1
    fi

    log_message "덤프 파일 적용 완료"

    rm $dump_file
    log_message "데이터베이스 복사가 완료되었습니다."
}

# 스토리지 복사 함수
copy_storage() {
    local source_project_id=$1
    local target_project_id=$2

    echo "스토리지 복사를 시작합니다..."

    # 임시 디렉토리 생성
    local temp_dir="temp_storage"
    mkdir -p $temp_dir

    # 소스 프로젝트의 모든 버킷 리스트 가져오기
    local buckets
    if [ "$source_project_id" == "local" ]; then
        buckets=$(supabase storage ls --local)
    else
        buckets=$(supabase storage ls)
    fi

    if [ $? -ne 0 ]; then
        echo "버킷 목록을 가져오는데 실패했습니다."
        return 1
    fi

    for bucket in $buckets; do
        echo "버킷 복사 중: $bucket"

        # 타겟 프로젝트에 버킷 생성 (이미 존재하면 무시)
        if [ "$target_project_id" == "local" ]; then
            supabase storage create $bucket --local || true
        else
            supabase storage create $bucket || true
        fi

        # 버킷 내의 모든 파일 리스트 가져오기
        local files
        if [ "$source_project_id" == "local" ]; then
            files=$(supabase storage ls $bucket --local)
        else
            files=$(supabase storage ls $bucket)
        fi

        for file in $files; do
            echo "파일 복사 중: $file"

            # 파일 다운로드
            if [ "$source_project_id" == "local" ]; then
                supabase storage download $bucket/$file -o $temp_dir/$file --local
            else
                supabase storage download $bucket/$file -o $temp_dir/$file
            fi

            # 파일 업로드
            if [ "$target_project_id" == "local" ]; then
                supabase storage upload $bucket $temp_dir/$file --local
            else
                supabase storage upload $bucket $temp_dir/$file
            fi

            # 임시 파일 삭제
            rm $temp_dir/$file
        done
    done

    # 임시 디렉토리 삭제
    rm -r $temp_dir

    echo "스토리지 복사가 완료되었습니다."
}

# 함수 복사 함수
copy_functions() {
    local source_project_id=$1
    local target_project_id=$2

    echo "함수 복사를 시작합니다..."

    # Edge Function 목록 가져오기
    local functions=$(supabase functions list --project-ref $source_project_id)

    echo "$functions"

    if [ $? -ne 0 ]; then
        echo "함수 목록을 가져오는데 실패했습니다."
        return 1
    fi

    # 함수 이름과 JWT 설정 추출 (수정된 부분)
    local function_info=$(echo "$functions" |
      sed 's/\x1b\[[0-9;]*m//g' |
      sed '1,2d' |
      sed 's/│/|/g' |
      awk -F'|' '{print $3}' |
      sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
      sed '1,2d')

    if [ -z "$function_info" ]; then
        echo "추출된 함수 정보가 없습니다. 스크립트를 종료합니다."
        return 1
    fi

    echo "추출된 함수 정보:"
    echo "$function_info"

    # 각 함수 복사
    echo "$function_info" | while read -r func; do
        echo "함수 복사 중: $func"

        # 함수 다운로드
        echo "함수 다운로드 시작: $func"
        supabase functions download "$func" --project-ref $source_project_id --debug
        download_result=$?

        if [ $download_result -ne 0 ]; then
            echo "함수 $func 다운로드에 실패했습니다."
        else
            echo "함수 $func 다운로드 성공"
        fi

    done

    echo "함수 복사가 완료되었습니다."
}

# 복사 실행 함수
execute_copy() {
    local source_project_id=$1
    local target_project_id=$2
    local source_db_password=$3
    local target_db_password=$4
    shift 4
    local components=("$@")

    for component in "${components[@]}"; do
        case $component in
            database)
                copy_database "$source_project_id" "$target_project_id" "$source_db_password" "$target_db_password"
                ;;
            storage)
                copy_storage "$source_project_id" "$target_project_id"
                ;;
            functions)
                copy_functions "$source_project_id" "$target_project_id"
                ;;
        esac
    done
}

# 사용법 출력 함수
print_usage() {
    echo "사용법: $0 [--all|-a] [--database|-d] [--storage|-s] [--functions|-f]"
    echo "  --all, -a        : 모든 컴포넌트 복사 (데이터베이스, 스토리지, 함수)"
    echo "  --database, -d   : 데이터베이스 복사"
    echo "  --storage, -s    : 스토리지 복사"
    echo "  --functions, -f  : 함수 복사"
}