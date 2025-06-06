-- 투표 아이템 신청을 위한 데이터베이스 스키마 생성
-- 작성일: 2025-06-06

-- 필요한 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. vote_item_requests 테이블 생성
CREATE TABLE IF NOT EXISTS "public"."vote_item_requests" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "vote_id" INTEGER NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT "vote_item_requests_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "vote_item_requests_vote_id_fkey" FOREIGN KEY ("vote_id") REFERENCES "public"."vote"("id") ON DELETE CASCADE,
    CONSTRAINT "vote_item_requests_status_check" CHECK ("status" IN ('pending', 'approved', 'rejected'))
);

-- 2. vote_item_request_users 테이블 생성
CREATE TABLE IF NOT EXISTS "public"."vote_item_request_users" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "vote_item_request_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "artist_name" VARCHAR(255) NOT NULL,
    "artist_group" VARCHAR(255),
    "reason" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT "vote_item_request_users_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "vote_item_request_users_vote_item_request_id_fkey" FOREIGN KEY ("vote_item_request_id") REFERENCES "public"."vote_item_requests"("id") ON DELETE CASCADE,
    CONSTRAINT "vote_item_request_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE,
    CONSTRAINT "vote_item_request_users_status_check" CHECK ("status" IN ('pending', 'approved', 'rejected')),
    CONSTRAINT "vote_item_request_users_unique_user_vote" UNIQUE ("vote_item_request_id", "user_id")
);

-- 3. 인덱스 생성
-- vote_item_requests 테이블 인덱스
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_vote_id" ON "public"."vote_item_requests" ("vote_id");
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_status" ON "public"."vote_item_requests" ("status");
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_vote_id_status" ON "public"."vote_item_requests" ("vote_id", "status");
CREATE INDEX IF NOT EXISTS "idx_vote_item_requests_created_at" ON "public"."vote_item_requests" ("created_at");

-- vote_item_request_users 테이블 인덱스
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_vote_item_request_id" ON "public"."vote_item_request_users" ("vote_item_request_id");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_user_id" ON "public"."vote_item_request_users" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_user_id_status" ON "public"."vote_item_request_users" ("user_id", "status");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_artist_name" ON "public"."vote_item_request_users" ("artist_name");
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_created_at" ON "public"."vote_item_request_users" ("created_at");

-- 아티스트명 검색을 위한 GIN 인덱스 (부분 문자열 검색 지원)
CREATE INDEX IF NOT EXISTS "idx_vote_item_request_users_artist_name_gin" ON "public"."vote_item_request_users" USING GIN ("artist_name" gin_trgm_ops);

-- 4. 보안 함수 생성
-- 투표 생성자 확인 함수
CREATE OR REPLACE FUNCTION "public"."is_vote_creator"("vote_id" INTEGER) 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 현재는 투표 생성자 정보가 vote 테이블에 없으므로 관리자만 허용
    -- 추후 vote 테이블에 creator_id 컬럼이 추가되면 수정 필요
    RETURN "public"."is_admin"();
END;
$$;

-- 관리자 확인 함수
CREATE OR REPLACE FUNCTION "public"."is_admin"() 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 현재는 모든 인증된 사용자를 관리자로 처리 (개발 단계)
    -- 추후 user_profiles 테이블에 role 컬럼 추가 후 수정 필요
    RETURN auth.uid() IS NOT NULL;
END;
$$;

-- 투표 아이템 신청 가능 상태 확인 함수
CREATE OR REPLACE FUNCTION "public"."is_vote_item_request_open"("vote_id" INTEGER) 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    vote_start_at TIMESTAMP;
    vote_stop_at TIMESTAMP;
    now_time TIMESTAMP;
BEGIN
    SELECT start_at, stop_at INTO vote_start_at, vote_stop_at
    FROM "public"."vote"
    WHERE id = vote_id;
    
    now_time := NOW();
    
    -- 투표가 시작되기 전이거나 진행 중일 때만 신청 가능
    RETURN (vote_start_at IS NULL OR now_time < vote_stop_at);
END;
$$;

-- 5. RLS 정책 설정
-- vote_item_requests 테이블 RLS 활성화
ALTER TABLE "public"."vote_item_requests" ENABLE ROW LEVEL SECURITY;

-- vote_item_requests 읽기 정책
CREATE POLICY "vote_item_requests_select_policy" ON "public"."vote_item_requests"
    FOR SELECT USING (
        -- 승인된 신청은 모든 인증된 사용자가 조회 가능
        (status = 'approved' AND auth.uid() IS NOT NULL) OR
        -- 투표 생성자는 모든 신청 조회 가능
        "public"."is_vote_creator"(vote_id) OR
        -- 관리자는 모든 신청 조회 가능
        "public"."is_admin"()
    );

-- vote_item_requests 생성 정책
CREATE POLICY "vote_item_requests_insert_policy" ON "public"."vote_item_requests"
    FOR INSERT WITH CHECK (
        -- 인증된 사용자만 생성 가능
        auth.uid() IS NOT NULL AND
        -- 투표가 신청 가능한 상태일 때만 생성 가능
        "public"."is_vote_item_request_open"(vote_id)
    );

-- vote_item_requests 수정 정책
CREATE POLICY "vote_item_requests_update_policy" ON "public"."vote_item_requests"
    FOR UPDATE USING (
        -- 투표 생성자 또는 관리자만 수정 가능
        "public"."is_vote_creator"(vote_id) OR "public"."is_admin"()
    );

-- vote_item_requests 삭제 정책
CREATE POLICY "vote_item_requests_delete_policy" ON "public"."vote_item_requests"
    FOR DELETE USING (
        -- 투표 생성자 또는 관리자만 삭제 가능
        "public"."is_vote_creator"(vote_id) OR "public"."is_admin"()
    );

-- vote_item_request_users 테이블 RLS 활성화
ALTER TABLE "public"."vote_item_request_users" ENABLE ROW LEVEL SECURITY;

-- vote_item_request_users 읽기 정책
CREATE POLICY "vote_item_request_users_select_policy" ON "public"."vote_item_request_users"
    FOR SELECT USING (
        -- 사용자는 자신의 신청만 조회 가능
        user_id = auth.uid() OR
        -- 투표 생성자는 해당 투표의 모든 사용자 신청 조회 가능
        EXISTS (
            SELECT 1 FROM "public"."vote_item_requests" vir 
            WHERE vir.id = vote_item_request_id AND "public"."is_vote_creator"(vir.vote_id)
        ) OR
        -- 관리자는 모든 사용자 신청 조회 가능
        "public"."is_admin"()
    );

-- vote_item_request_users 생성 정책
CREATE POLICY "vote_item_request_users_insert_policy" ON "public"."vote_item_request_users"
    FOR INSERT WITH CHECK (
        -- 인증된 사용자만 자신의 신청 생성 가능
        user_id = auth.uid() AND
        -- 투표가 신청 가능한 상태인지 확인
        EXISTS (
            SELECT 1 FROM "public"."vote_item_requests" vir 
            WHERE vir.id = vote_item_request_id AND "public"."is_vote_item_request_open"(vir.vote_id)
        )
    );

-- vote_item_request_users 수정 정책
CREATE POLICY "vote_item_request_users_update_policy" ON "public"."vote_item_request_users"
    FOR UPDATE USING (
        -- 사용자는 자신의 pending 상태 신청만 수정 가능
        (user_id = auth.uid() AND status = 'pending') OR
        -- 투표 생성자는 신청 상태 변경 가능
        EXISTS (
            SELECT 1 FROM "public"."vote_item_requests" vir 
            WHERE vir.id = vote_item_request_id AND "public"."is_vote_creator"(vir.vote_id)
        ) OR
        -- 관리자는 모든 신청 수정 가능
        "public"."is_admin"()
    );

-- vote_item_request_users 삭제 정책
CREATE POLICY "vote_item_request_users_delete_policy" ON "public"."vote_item_request_users"
    FOR DELETE USING (
        -- 사용자는 자신의 pending 상태 신청만 삭제 가능
        (user_id = auth.uid() AND status = 'pending') OR
        -- 투표 생성자는 모든 신청 삭제 가능
        EXISTS (
            SELECT 1 FROM "public"."vote_item_requests" vir 
            WHERE vir.id = vote_item_request_id AND "public"."is_vote_creator"(vir.vote_id)
        ) OR
        -- 관리자는 모든 신청 삭제 가능
        "public"."is_admin"()
    );

-- 6. 권한 부여
-- 테이블 권한
GRANT ALL ON TABLE "public"."vote_item_requests" TO "anon";
GRANT ALL ON TABLE "public"."vote_item_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."vote_item_requests" TO "service_role";

GRANT ALL ON TABLE "public"."vote_item_request_users" TO "anon";
GRANT ALL ON TABLE "public"."vote_item_request_users" TO "authenticated";
GRANT ALL ON TABLE "public"."vote_item_request_users" TO "service_role";

-- 함수 권한
GRANT ALL ON FUNCTION "public"."is_vote_creator"(INTEGER) TO "anon";
GRANT ALL ON FUNCTION "public"."is_vote_creator"(INTEGER) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_vote_creator"(INTEGER) TO "service_role";

GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";

GRANT ALL ON FUNCTION "public"."is_vote_item_request_open"(INTEGER) TO "anon";
GRANT ALL ON FUNCTION "public"."is_vote_item_request_open"(INTEGER) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_vote_item_request_open"(INTEGER) TO "service_role";

-- 7. 실시간 구독 설정 (선택사항)
-- ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vote_item_requests";
-- ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vote_item_request_users";

-- 마이그레이션 완료 로그
DO $$
BEGIN
    RAISE NOTICE '투표 아이템 신청 스키마 마이그레이션이 성공적으로 완료되었습니다.';
END $$;
