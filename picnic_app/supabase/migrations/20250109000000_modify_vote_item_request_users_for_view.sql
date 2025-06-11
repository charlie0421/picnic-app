-- vote_item_request_users 테이블 수정 및 vote_item_requests 뷰 변경
-- 작성일: 2025-01-09
-- 설명: vote_item_requests를 뷰로 변경하기 위해 vote_item_request_users에 vote_id 추가

-- 1. 기존 외래키 제약 조건 제거 (뷰로 변경하기 전에)
ALTER TABLE "public"."vote_item_request_users" 
DROP CONSTRAINT IF EXISTS "vote_item_request_users_vote_item_request_id_fkey";

-- 2. vote_item_request_users 테이블에 vote_id 컬럼 추가
ALTER TABLE "public"."vote_item_request_users" 
ADD COLUMN IF NOT EXISTS "vote_id" INTEGER NOT NULL DEFAULT 0;

-- 3. vote_id에 대한 외래키 제약 조건 추가 (존재하지 않는 경우에만)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'vote_item_request_users' 
        AND constraint_name = 'vote_item_request_users_vote_id_fkey'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE "public"."vote_item_request_users" 
        ADD CONSTRAINT "vote_item_request_users_vote_id_fkey" 
        FOREIGN KEY ("vote_id") REFERENCES "public"."vote"("id") ON DELETE CASCADE;
    END IF;
END $$;

-- 4. vote_id에 대한 인덱스 추가
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_vote_id" 
ON "public"."vote_item_request_users" ("vote_id");

-- 4. 복합 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_vote_user_artist" 
ON "public"."vote_item_request_users" ("vote_id", "user_id", "artist_id");

-- 5. 기존 데이터 마이그레이션 (vote_item_requests에서 vote_id 가져오기)
UPDATE "public"."vote_item_request_users" viru
SET vote_id = vir.vote_id
FROM "public"."vote_item_requests" vir
WHERE viru.vote_item_request_id = vir.id
AND viru.vote_id = 0;

-- 5.1. vote_item_request_id 컬럼을 각 레코드의 고유 ID로 변경
UPDATE "public"."vote_item_request_users" 
SET vote_item_request_id = id 
WHERE vote_item_request_id != id;

-- 6. 유니크 제약 조건 수정 (vote_id 기반으로 변경)
ALTER TABLE "public"."vote_item_request_users" 
DROP CONSTRAINT IF EXISTS "vote_item_request_users_unique_user_artist_vote";

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'vote_item_request_users' 
        AND constraint_name = 'vote_item_request_users_unique_vote_user_artist'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE "public"."vote_item_request_users" 
        ADD CONSTRAINT "vote_item_request_users_unique_vote_user_artist" 
        UNIQUE ("vote_id", "user_id", "artist_id");
    END IF;
END $$;

-- 7. status 컬럼 추가 (개별 신청 상태 관리)
ALTER TABLE "public"."vote_item_request_users" 
ADD COLUMN IF NOT EXISTS "status" VARCHAR(50) NOT NULL DEFAULT 'pending';

-- 8. status 제약 조건 추가 (존재하지 않는 경우에만)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'vote_item_request_users' 
        AND constraint_name = 'vote_item_request_users_status_check'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE "public"."vote_item_request_users" 
        ADD CONSTRAINT "vote_item_request_users_status_check" 
        CHECK ("status" IN ('pending', 'approved', 'rejected', 'in-progress', 'cancelled'));
    END IF;
END $$;

-- 9. status 인덱스 추가
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_status" 
ON "public"."vote_item_request_users" ("status");

CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_vote_status" 
ON "public"."vote_item_request_users" ("vote_id", "status");

-- 10. 기존 vote_item_requests 처리 (테이블/뷰 구분)
DO $$
BEGIN
    -- 백업 테이블이 이미 존재하는지 확인
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'vote_item_requests_backup' 
        AND table_schema = 'public'
    ) THEN
        -- vote_item_requests가 테이블인 경우 백업으로 이름 변경
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'vote_item_requests' 
            AND table_schema = 'public'
            AND table_type = 'BASE TABLE'
        ) THEN
            ALTER TABLE "public"."vote_item_requests" 
            RENAME TO "vote_item_requests_backup";
        END IF;
    END IF;
    
    -- vote_item_requests가 뷰인 경우 삭제
    IF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'vote_item_requests' 
        AND table_schema = 'public'
    ) THEN
        DROP VIEW "public"."vote_item_requests" CASCADE;
    END IF;
    
    -- vote_item_requests가 테이블이고 백업이 이미 존재하는 경우 테이블 삭제
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'vote_item_requests' 
        AND table_schema = 'public'
        AND table_type = 'BASE TABLE'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'vote_item_requests_backup' 
        AND table_schema = 'public'
    ) THEN
        DROP TABLE "public"."vote_item_requests" CASCADE;
    END IF;
END $$;

-- 11. vote_item_requests를 뷰로 재생성 (아티스트 정보 포함)
CREATE OR REPLACE VIEW "public"."vote_item_requests" AS
SELECT 
    viru.id,
    viru.vote_id,
    viru.status,
    viru.created_at,
    viru.updated_at,
    viru.user_id,
    viru.artist_id,
    -- 아티스트 정보 (artist 테이블이 있는 경우)
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'artist'
        ) THEN 
            (SELECT row_to_json(a.*) FROM "public"."artist" a WHERE a.id = viru.artist_id)
        ELSE 
            json_build_object('id', viru.artist_id, 'name', json_build_object('ko', 'Unknown', 'en', 'Unknown'))
    END as artist
FROM "public"."vote_item_request_users" viru;

-- 12. 뷰 권한 설정
GRANT SELECT ON "public"."vote_item_requests" TO "anon";
GRANT SELECT ON "public"."vote_item_requests" TO "authenticated";
GRANT SELECT ON "public"."vote_item_requests" TO "service_role";

-- 13. 기존 함수들 삭제 (매개변수 변경을 위해)
DROP FUNCTION IF EXISTS "public"."create_vote_item_request_with_user"(INTEGER, INTEGER, UUID) CASCADE;
DROP FUNCTION IF EXISTS "public"."get_artist_request_count"(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS "public"."has_user_requested_artist"(INTEGER, INTEGER, UUID) CASCADE;

-- 14. 함수 재생성 - create_vote_item_request_with_user
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
        WHERE viru.vote_id = vote_id_param 
        AND viru.user_id = user_id_param 
        AND viru.artist_id = artist_id_param
    ) THEN
        RAISE EXCEPTION '이미 해당 아티스트에 대해 신청하셨습니다.';
    END IF;
    
    -- 아티스트가 존재하는지 확인
    IF NOT EXISTS (
        SELECT 1 FROM "public"."artist" WHERE id = artist_id_param
    ) THEN
        RAISE EXCEPTION '존재하지 않는 아티스트입니다.';
    END IF;
    
    -- 새로운 요청 ID 생성
    new_request_id := uuid_generate_v4();
    
    -- 사용자 신청 정보 생성 (vote_id 포함)
    INSERT INTO "public"."vote_item_request_users" (
        id,
        vote_item_request_id,
        vote_id,
        user_id, 
        artist_id,
        status
    )
    VALUES (
        new_request_id,
        new_request_id,  -- vote_item_request_id는 자신의 id와 동일
        vote_id_param,
        user_id_param, 
        artist_id_param,
        'pending'
    );
    
    -- 생성된 요청과 사용자 정보 반환 (artist 정보 포함)
    SELECT jsonb_build_object(
        'vote_item_request', jsonb_build_object(
            'id', new_request_id,
            'vote_id', vote_id_param,
            'status', 'pending',
            'created_at', NOW(),
            'updated_at', NOW()
        ),
        'user_request', to_jsonb(viru.*),
        'artist', to_jsonb(a.*)
    ) INTO result_data
    FROM "public"."vote_item_request_users" viru
    JOIN "public"."artist" a ON viru.artist_id = a.id
    WHERE viru.vote_item_request_id = new_request_id AND viru.user_id = user_id_param;
    
    RETURN result_data;
END;
$$;

-- 15. 함수 재생성 - get_artist_request_count
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
    WHERE viru.vote_id = vote_id_param AND viru.artist_id = artist_id_param;
    
    RETURN COALESCE(request_count, 0);
END;
$$;

-- 16. 함수 재생성 - has_user_requested_artist
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
        WHERE viru.vote_id = vote_id_param 
        AND viru.artist_id = artist_id_param 
        AND viru.user_id = user_id_param
    );
END;
$$;

-- 17. 기존 뷰들 재생성 (새로운 구조에 맞게)
CREATE OR REPLACE VIEW "public"."vote_item_request_status_summary" AS
SELECT 
    viru.vote_id,
    viru.status as request_status,
    a.id as artist_id,
    (a.name->>'ko') as artist_name,
    (ag.name->>'ko') as artist_group,
    COUNT(*) as request_count,
    MIN(viru.created_at) as first_request_at,
    MAX(viru.updated_at) as last_updated_at
FROM "public"."vote_item_request_users" viru
JOIN "public"."artist" a ON viru.artist_id = a.id
LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
GROUP BY viru.vote_id, viru.status, a.id, (a.name->>'ko'), (ag.name->>'ko')
ORDER BY request_count DESC;

CREATE OR REPLACE VIEW "public"."user_vote_item_request_history" AS
SELECT 
    viru.user_id,
    viru.vote_id,
    viru.status as request_status,
    a.id as artist_id,
    (a.name->>'ko') as artist_name,
    (ag.name->>'ko') as artist_group,
    a.image as artist_image,
    viru.created_at as requested_at,
    viru.updated_at as status_updated_at,
    CASE 
        WHEN viru.status = 'pending' THEN '요청 대기중'
        WHEN viru.status = 'approved' THEN '요청 승인됨'
        WHEN viru.status = 'rejected' THEN '요청 거절됨'
        WHEN viru.status = 'in-progress' THEN '요청 진행중'
        WHEN viru.status = 'cancelled' THEN '요청 취소됨'
        ELSE '요청 상태 알 수 없음'
    END as request_status_text
FROM "public"."vote_item_request_users" viru
JOIN "public"."artist" a ON viru.artist_id = a.id
LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
ORDER BY viru.created_at DESC;

CREATE OR REPLACE VIEW "public"."artist_request_statistics" AS
SELECT 
    a.id as artist_id,
    (a.name->>'ko') as artist_name,
    (ag.name->>'ko') as artist_group,
    a.image as artist_image,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN viru.status = 'pending' THEN 1 END) as pending_requests,
    COUNT(CASE WHEN viru.status = 'approved' THEN 1 END) as approved_requests,
    COUNT(CASE WHEN viru.status = 'rejected' THEN 1 END) as rejected_requests,
    MIN(viru.created_at) as first_request_at,
    MAX(viru.updated_at) as last_updated_at
FROM "public"."vote_item_request_users" viru
JOIN "public"."artist" a ON viru.artist_id = a.id
LEFT JOIN "public"."artist_group" ag ON a.group_id = ag.id
GROUP BY a.id, (a.name->>'ko'), (ag.name->>'ko'), a.image
ORDER BY total_requests DESC;

-- 18. 뷰 권한 설정
GRANT SELECT ON "public"."vote_item_request_status_summary" TO "authenticated";
GRANT SELECT ON "public"."user_vote_item_request_history" TO "authenticated";
GRANT SELECT ON "public"."artist_request_statistics" TO "authenticated";

-- 19. 함수 권한 설정
GRANT ALL ON FUNCTION "public"."create_vote_item_request_with_user"(INTEGER, INTEGER, UUID) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_vote_item_request_with_user"(INTEGER, INTEGER, UUID) TO "service_role";
GRANT ALL ON FUNCTION "public"."get_artist_request_count"(INTEGER, INTEGER) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_artist_request_count"(INTEGER, INTEGER) TO "service_role";
GRANT ALL ON FUNCTION "public"."has_user_requested_artist"(INTEGER, INTEGER, UUID) TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_user_requested_artist"(INTEGER, INTEGER, UUID) TO "service_role";

-- 마이그레이션 완료 로그
DO $$
BEGIN
    RAISE NOTICE 'vote_item_request_users 테이블 수정 및 vote_item_requests 뷰 변경이 완료되었습니다.';
    RAISE NOTICE '- vote_item_request_users에 vote_id, status 컬럼 추가';
    RAISE NOTICE '- vote_item_requests를 뷰로 변경';
    RAISE NOTICE '- 관련 함수 및 뷰 업데이트';
    RAISE NOTICE '- 기존 vote_item_requests 테이블은 vote_item_requests_backup으로 백업됨';
END $$; 