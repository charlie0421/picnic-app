-- 투표 아이템 요청 스키마 리팩토링 마이그레이션
-- 작성일: 2025-06-08
-- 설명: vote_item_requests에서 title, description 제거하고 status 추가
--       vote_item_request_users에서 artist_name, artist_group, reason, status 제거하고 artist_id 추가

-- 1. 기존 뷰와 함수 삭제 (의존성 제거)
DROP VIEW IF EXISTS "public"."vote_item_request_status_summary" CASCADE;
DROP VIEW IF EXISTS "public"."user_vote_item_request_history" CASCADE;
DROP VIEW IF EXISTS "public"."artist_request_statistics" CASCADE;
DROP FUNCTION IF EXISTS "public"."create_vote_item_request_with_user"(JSONB, JSONB, UUID) CASCADE;

-- 2. vote_item_requests 테이블 구조 변경
-- title, description 컬럼 제거 및 status 컬럼 추가
ALTER TABLE "public"."vote_item_requests" 
DROP COLUMN IF EXISTS "title",
DROP COLUMN IF EXISTS "description",
ADD COLUMN IF NOT EXISTS "status" VARCHAR(50) NOT NULL DEFAULT 'pending';

-- status 컬럼에 대한 제약 조건 추가
ALTER TABLE "public"."vote_item_requests" 
DROP CONSTRAINT IF EXISTS "vote_item_requests_status_check";

ALTER TABLE "public"."vote_item_requests" 
ADD CONSTRAINT "vote_item_requests_status_check" 
CHECK ("status" IN ('pending', 'approved', 'rejected', 'in-progress', 'cancelled'));

-- 3. vote_item_request_users 테이블의 정책 삭제 (컬럼 의존성 제거)
DROP POLICY IF EXISTS "vote_item_request_users_update_policy" ON "public"."vote_item_request_users";
DROP POLICY IF EXISTS "vote_item_request_users_delete_policy" ON "public"."vote_item_request_users";
DROP POLICY IF EXISTS "vote_item_request_users_select_policy" ON "public"."vote_item_request_users";
DROP POLICY IF EXISTS "vote_item_request_users_insert_policy" ON "public"."vote_item_request_users";

-- 4. vote_item_request_users 테이블 구조 변경
-- 기존 컬럼들 제거 및 artist_id 추가
ALTER TABLE "public"."vote_item_request_users" 
DROP COLUMN IF EXISTS "artist_name",
DROP COLUMN IF EXISTS "artist_group", 
DROP COLUMN IF EXISTS "reason",
DROP COLUMN IF EXISTS "status",
ADD COLUMN IF NOT EXISTS "artist_id" INTEGER NOT NULL DEFAULT 0;

-- artist_id에 대한 외래키 제약 조건 추가 (artist 테이블이 존재하는 경우에만)
ALTER TABLE "public"."vote_item_request_users" 
DROP CONSTRAINT IF EXISTS "vote_item_request_users_artist_id_fkey";

-- artist 테이블이 존재하는 경우에만 외래키 제약 조건 추가
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        ALTER TABLE "public"."vote_item_request_users" 
        ADD CONSTRAINT "vote_item_request_users_artist_id_fkey" 
        FOREIGN KEY ("artist_id") REFERENCES "public"."artist"("id") ON DELETE CASCADE;
    END IF;
END $$;

-- 5. 기존 인덱스 정리 및 새로운 인덱스 추가
-- vote_item_requests 테이블 인덱스
DROP INDEX IF EXISTS "idx_vote_item_requests_title";
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_status" ON "public"."vote_item_requests" ("status");
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_vote_id_status" ON "public"."vote_item_requests" ("vote_id", "status");

-- vote_item_request_users 테이블 인덱스 정리
DROP INDEX IF EXISTS "idx_vote_item_request_users_artist_name";
DROP INDEX IF EXISTS "idx_vote_item_request_users_artist_name_gin";

-- 새로운 인덱스 추가
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_artist_id" ON "public"."vote_item_request_users" ("artist_id");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_vote_request_artist" ON "public"."vote_item_request_users" ("vote_item_request_id", "artist_id");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_user_artist" ON "public"."vote_item_request_users" ("user_id", "artist_id");

-- 6. 중복 방지를 위한 유니크 제약 조건 수정
-- 기존 제약 조건 삭제
ALTER TABLE "public"."vote_item_request_users" 
DROP CONSTRAINT IF EXISTS "vote_item_request_users_unique_user_vote";

-- 새로운 유니크 제약 조건 추가 (같은 투표에서 같은 사용자가 같은 아티스트에 대해 중복 신청 방지)
-- 이미 존재하는 경우 무시
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'vote_item_request_users' 
        AND constraint_name = 'vote_item_request_users_unique_user_artist_vote'
    ) THEN
        ALTER TABLE "public"."vote_item_request_users" 
        ADD CONSTRAINT "vote_item_request_users_unique_user_artist_vote" 
        UNIQUE ("vote_item_request_id", "user_id", "artist_id");
    END IF;
END $$;

-- 7. 개선된 뷰 생성 (artist 테이블이 존재하는 경우에만)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        -- 투표별 신청 상태 요약 뷰 (artist 정보 포함)
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."vote_item_request_status_summary" AS
        SELECT 
            vir.vote_id,
            vir.status as request_status,
            a.id as artist_id,
            (a.name->>''ko'') as artist_name,
            (ag.name->>''ko'') as artist_group,
            COUNT(*) as request_count,
            MIN(viru.created_at) as first_request_at,
            MAX(viru.updated_at) as last_updated_at
        FROM "public"."vote_item_requests" vir
        JOIN "public"."vote_item_request_users" viru ON vir.id = viru.vote_item_request_id
        JOIN "public"."artist" a ON viru.artist_id = a.id
        LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
        GROUP BY vir.vote_id, vir.status, a.id, (a.name->>''ko''), (ag.name->>''ko'')';
    ELSE
        -- artist 테이블이 없는 경우 기본 뷰
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."vote_item_request_status_summary" AS
        SELECT 
            vir.vote_id,
            vir.status as request_status,
            viru.artist_id,
            ''Unknown'' as artist_name,
            ''Unknown'' as artist_group,
            COUNT(*) as request_count,
            MIN(viru.created_at) as first_request_at,
            MAX(viru.updated_at) as last_updated_at
        FROM "public"."vote_item_requests" vir
        JOIN "public"."vote_item_request_users" viru ON vir.id = viru.vote_item_request_id
        GROUP BY vir.vote_id, vir.status, viru.artist_id';
    END IF;
END $$;

-- 사용자별 투표 아이템 신청 히스토리 뷰 (artist 정보 포함)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."user_vote_item_request_history" AS
        SELECT 
            viru.user_id,
            vir.vote_id,
            vir.status as request_status,
            a.id as artist_id,
            (a.name->>''ko'') as artist_name,
            (ag.name->>''ko'') as artist_group,
            a.image as artist_image,
            viru.created_at as requested_at,
            viru.updated_at as status_updated_at,
            CASE 
                WHEN vir.status = ''pending'' THEN ''요청 대기중''
                WHEN vir.status = ''approved'' THEN ''요청 승인됨''
                WHEN vir.status = ''rejected'' THEN ''요청 거절됨''
                WHEN vir.status = ''in-progress'' THEN ''요청 진행중''
                WHEN vir.status = ''cancelled'' THEN ''요청 취소됨''
                ELSE ''요청 상태 알 수 없음''
            END as request_status_text
        FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        JOIN "public"."artist" a ON viru.artist_id = a.id
        LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
        ORDER BY viru.created_at DESC';
    ELSE
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."user_vote_item_request_history" AS
        SELECT 
            viru.user_id,
            vir.vote_id,
            vir.status as request_status,
            viru.artist_id,
            ''Unknown'' as artist_name,
            ''Unknown'' as artist_group,
            '''' as artist_image,
            viru.created_at as requested_at,
            viru.updated_at as status_updated_at,
            CASE 
                WHEN vir.status = ''pending'' THEN ''요청 대기중''
                WHEN vir.status = ''approved'' THEN ''요청 승인됨''
                WHEN vir.status = ''rejected'' THEN ''요청 거절됨''
                WHEN vir.status = ''in-progress'' THEN ''요청 진행중''
                WHEN vir.status = ''cancelled'' THEN ''요청 취소됨''
                ELSE ''요청 상태 알 수 없음''
            END as request_status_text
        FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        ORDER BY viru.created_at DESC';
    END IF;
END $$;

-- 아티스트별 신청 통계 뷰 (정규화된 구조)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."artist_request_statistics" AS
        SELECT 
            a.id as artist_id,
            (a.name->>''ko'') as artist_name,
            (ag.name->>''ko'') as artist_group,
            a.image as artist_image,
            COUNT(*) as total_requests,
            COUNT(CASE WHEN vir.status = ''pending'' THEN 1 END) as pending_requests,
            COUNT(CASE WHEN vir.status = ''approved'' THEN 1 END) as approved_requests,
            COUNT(CASE WHEN vir.status = ''rejected'' THEN 1 END) as rejected_requests,
            MIN(viru.created_at) as first_request_at,
            MAX(viru.updated_at) as last_updated_at
        FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        JOIN "public"."artist" a ON viru.artist_id = a.id
        LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
        GROUP BY a.id, (a.name->>''ko''), (ag.name->>''ko''), a.image
        ORDER BY total_requests DESC';
    ELSE
        EXECUTE '
        CREATE OR REPLACE VIEW "public"."artist_request_statistics" AS
        SELECT 
            viru.artist_id,
            ''Unknown'' as artist_name,
            ''Unknown'' as artist_group,
            '''' as artist_image,
            COUNT(*) as total_requests,
            COUNT(CASE WHEN vir.status = ''pending'' THEN 1 END) as pending_requests,
            COUNT(CASE WHEN vir.status = ''approved'' THEN 1 END) as approved_requests,
            COUNT(CASE WHEN vir.status = ''rejected'' THEN 1 END) as rejected_requests,
            MIN(viru.created_at) as first_request_at,
            MAX(viru.updated_at) as last_updated_at
        FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        GROUP BY viru.artist_id
        ORDER BY total_requests DESC';
    END IF;
END $$;

-- 8. 뷰 권한 설정
GRANT SELECT ON "public"."vote_item_request_status_summary" TO "authenticated";
GRANT SELECT ON "public"."user_vote_item_request_history" TO "authenticated";
GRANT SELECT ON "public"."artist_request_statistics" TO "authenticated";

-- 9. 개선된 함수 생성 (정규화된 구조 기반)
-- 투표 아이템 신청과 사용자 정보를 함께 생성하는 함수
CREATE OR REPLACE FUNCTION "public"."create_vote_item_request_with_user"(
    "vote_id_param" INTEGER,
    "artist_id_param" INTEGER,
    "user_id_param" UUID
) 
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_request_id UUID;
    result_data JSONB;
BEGIN
    -- 중복 신청 확인 (같은 투표, 같은 아티스트, 같은 사용자)
    IF EXISTS (
        SELECT 1 FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        WHERE vir.vote_id = vote_id_param 
        AND viru.user_id = user_id_param 
        AND viru.artist_id = artist_id_param
    ) THEN
        RAISE EXCEPTION '이미 해당 아티스트에 대해 신청하셨습니다.';
    END IF;
    
    -- 아티스트가 존재하는지 확인 (artist 테이블이 있는 경우에만)
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM "public"."artist" WHERE id = artist_id_param
        ) THEN
            RAISE EXCEPTION '존재하지 않는 아티스트입니다.';
        END IF;
    END IF;
    
    -- 투표 아이템 요청 생성
    INSERT INTO "public"."vote_item_requests" (vote_id, status)
    VALUES (vote_id_param, 'pending')
    RETURNING id INTO new_request_id;
    
    -- 사용자 신청 정보 생성
    INSERT INTO "public"."vote_item_request_users" (
        vote_item_request_id, 
        user_id, 
        artist_id
    )
    VALUES (
        new_request_id, 
        user_id_param, 
        artist_id_param
    );
    
    -- 생성된 요청과 사용자 정보 반환 (artist 정보 포함, artist 테이블이 있는 경우에만)
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'artist'
    ) THEN
        SELECT jsonb_build_object(
            'vote_item_request', to_jsonb(vir.*),
            'user_request', to_jsonb(viru.*),
            'artist', to_jsonb(a.*)
        ) INTO result_data
        FROM "public"."vote_item_requests" vir
        JOIN "public"."vote_item_request_users" viru ON vir.id = viru.vote_item_request_id
        JOIN "public"."artist" a ON viru.artist_id = a.id
        WHERE vir.id = new_request_id AND viru.user_id = user_id_param;
    ELSE
        SELECT jsonb_build_object(
            'vote_item_request', to_jsonb(vir.*),
            'user_request', to_jsonb(viru.*),
            'artist', jsonb_build_object('id', viru.artist_id, 'name', 'Unknown')
        ) INTO result_data
        FROM "public"."vote_item_requests" vir
        JOIN "public"."vote_item_request_users" viru ON vir.id = viru.vote_item_request_id
        WHERE vir.id = new_request_id AND viru.user_id = user_id_param;
    END IF;
    
    RETURN result_data;
END;
$$;

-- 특정 투표에서 특정 아티스트의 신청 수를 조회하는 함수
CREATE OR REPLACE FUNCTION "public"."get_artist_request_count"(
    "vote_id_param" INTEGER,
    "artist_id_param" INTEGER
) 
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO request_count
    FROM "public"."vote_item_request_users" viru
    JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
    WHERE vir.vote_id = vote_id_param AND viru.artist_id = artist_id_param;
    
    RETURN COALESCE(request_count, 0);
END;
$$;

-- 사용자가 특정 투표에서 특정 아티스트에 대해 신청했는지 확인하는 함수
CREATE OR REPLACE FUNCTION "public"."has_user_requested_artist"(
    "vote_id_param" INTEGER,
    "artist_id_param" INTEGER,
    "user_id_param" UUID
) 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM "public"."vote_item_request_users" viru
        JOIN "public"."vote_item_requests" vir ON viru.vote_item_request_id = vir.id
        WHERE vir.vote_id = vote_id_param 
        AND viru.artist_id = artist_id_param 
        AND viru.user_id = user_id_param
    );
END;
$$;

-- 9. 함수 권한 설정
GRANT ALL ON FUNCTION "public"."create_vote_item_request_with_user"(INTEGER, INTEGER, UUID) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_vote_item_request_with_user"(INTEGER, INTEGER, UUID) TO "service_role";
GRANT ALL ON FUNCTION "public"."get_artist_request_count"(INTEGER, INTEGER) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_artist_request_count"(INTEGER, INTEGER) TO "service_role";
GRANT ALL ON FUNCTION "public"."has_user_requested_artist"(INTEGER, INTEGER, UUID) TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_user_requested_artist"(INTEGER, INTEGER, UUID) TO "service_role";

-- 10. RLS 정책 재생성 (새로운 구조에 맞게)
-- vote_item_request_users 테이블에 대한 RLS 정책 재생성
CREATE POLICY "vote_item_request_users_select_policy" ON "public"."vote_item_request_users"
    FOR SELECT USING (true);

CREATE POLICY "vote_item_request_users_insert_policy" ON "public"."vote_item_request_users"
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "vote_item_request_users_update_policy" ON "public"."vote_item_request_users"
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "vote_item_request_users_delete_policy" ON "public"."vote_item_request_users"
    FOR DELETE USING (auth.uid() = user_id);

-- 11. 기존 데이터 정리 (필요시)
-- 기존 데이터가 있다면 artist_id를 0으로 설정된 레코드들을 정리
-- 실제 운영 환경에서는 데이터 마이그레이션 로직이 필요할 수 있음
DELETE FROM "public"."vote_item_request_users" WHERE artist_id = 0;

-- 마이그레이션 완료 로그
DO $$
BEGIN
    RAISE NOTICE '투표 아이템 요청 스키마 리팩토링이 완료되었습니다.';
    RAISE NOTICE '- vote_item_requests: title, description 제거, status 추가';
    RAISE NOTICE '- vote_item_request_users: artist_name, artist_group, reason, status 제거, artist_id 추가';
    RAISE NOTICE '- artist 테이블과 외래키 연결 설정';
    RAISE NOTICE '- 정규화된 구조로 뷰 및 함수 재생성';
END $$; 