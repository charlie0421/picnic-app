-- 투표 요청(VoteRequest) 시스템을 위한 데이터베이스 스키마 생성
-- 작성일: 2025-06-07
-- 설명: VoteRequest 및 VoteRequestUser 모델에 맞는 테이블 생성

-- 필요한 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. vote_requests 테이블 생성
CREATE TABLE IF NOT EXISTS "public"."vote_requests" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "vote_id" VARCHAR(255) NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT "vote_requests_pkey" PRIMARY KEY ("id")
);

-- 2. vote_request_users 테이블 생성
CREATE TABLE IF NOT EXISTS "public"."vote_request_users" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "vote_request_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT "vote_request_users_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "vote_request_users_vote_request_id_fkey" FOREIGN KEY ("vote_request_id") REFERENCES "public"."vote_requests"("id") ON DELETE CASCADE,
    CONSTRAINT "vote_request_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE,
    CONSTRAINT "vote_request_users_status_check" CHECK ("status" IN ('pending', 'approved', 'rejected', 'in-progress', 'cancelled')),
    CONSTRAINT "vote_request_users_unique_user_vote" UNIQUE ("vote_request_id", "user_id")
);

-- 3. 인덱스 생성
-- vote_requests 테이블 인덱스
CREATE INDEX IF NOT EXISTS "idx_vote_requests_vote_id" ON "public"."vote_requests" ("vote_id");
CREATE INDEX IF NOT EXISTS "idx_vote_requests_created_at" ON "public"."vote_requests" ("created_at");
CREATE INDEX IF NOT EXISTS "idx_vote_requests_title" ON "public"."vote_requests" ("title");

-- vote_request_users 테이블 인덱스
CREATE INDEX IF NOT EXISTS "idx_vote_request_users_vote_request_id" ON "public"."vote_request_users" ("vote_request_id");
CREATE INDEX IF NOT EXISTS "idx_vote_request_users_user_id" ON "public"."vote_request_users" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_vote_request_users_status" ON "public"."vote_request_users" ("status");
CREATE INDEX IF NOT EXISTS "idx_vote_request_users_user_id_status" ON "public"."vote_request_users" ("user_id", "status");
CREATE INDEX IF NOT EXISTS "idx_vote_request_users_created_at" ON "public"."vote_request_users" ("created_at");

-- 제목 검색을 위한 GIN 인덱스 (부분 문자열 검색 지원)
CREATE INDEX IF NOT EXISTS "idx_vote_requests_title_gin" ON "public"."vote_requests" USING GIN ("title" gin_trgm_ops);

-- 4. 보안 함수 생성 (기존 함수 재사용)
-- 관리자 확인 함수 (이미 존재하는 경우 재생성)
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

-- 투표 요청 소유자 확인 함수
CREATE OR REPLACE FUNCTION "public"."is_vote_request_owner"("request_id" UUID) 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM "public"."vote_request_users" vru
        WHERE vru.vote_request_id = request_id AND vru.user_id = auth.uid()
    );
END;
$$;

-- 5. 트랜잭션 함수 생성 (중복 방지 포함 투표 요청 생성)
CREATE OR REPLACE FUNCTION "public"."create_vote_request_with_user"(
    "request_data" JSONB,
    "user_id" UUID,
    "user_status" VARCHAR DEFAULT 'pending'
) 
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_request_id UUID;
    vote_id_param VARCHAR;
    result_request JSONB;
BEGIN
    -- JSON에서 vote_id 추출
    vote_id_param := request_data->>'vote_id';
    
    -- 중복 요청 확인
    IF EXISTS (
        SELECT 1 FROM "public"."vote_request_users" vru
        JOIN "public"."vote_requests" vr ON vru.vote_request_id = vr.id
        WHERE vr.vote_id = vote_id_param AND vru.user_id = user_id
    ) THEN
        RAISE EXCEPTION '이미 해당 투표에 요청하셨습니다.';
    END IF;
    
    -- 투표 요청 생성
    INSERT INTO "public"."vote_requests" (vote_id, title, description)
    VALUES (
        request_data->>'vote_id',
        request_data->>'title',
        request_data->>'description'
    )
    RETURNING id INTO new_request_id;
    
    -- 사용자 정보 생성
    INSERT INTO "public"."vote_request_users" (vote_request_id, user_id, status)
    VALUES (new_request_id, user_id, user_status);
    
    -- 생성된 요청 반환
    SELECT to_jsonb(vr.*) INTO result_request
    FROM "public"."vote_requests" vr
    WHERE vr.id = new_request_id;
    
    RETURN result_request;
END;
$$;

-- 6. RLS 정책 설정
-- vote_requests 테이블 RLS 활성화
ALTER TABLE "public"."vote_requests" ENABLE ROW LEVEL SECURITY;

-- vote_requests 읽기 정책
CREATE POLICY "vote_requests_select_policy" ON "public"."vote_requests"
    FOR SELECT USING (
        -- 모든 인증된 사용자가 조회 가능
        auth.uid() IS NOT NULL OR
        -- 관리자는 모든 요청 조회 가능
        "public"."is_admin"()
    );

-- vote_requests 생성 정책
CREATE POLICY "vote_requests_insert_policy" ON "public"."vote_requests"
    FOR INSERT WITH CHECK (
        -- 인증된 사용자만 생성 가능
        auth.uid() IS NOT NULL
    );

-- vote_requests 수정 정책
CREATE POLICY "vote_requests_update_policy" ON "public"."vote_requests"
    FOR UPDATE USING (
        -- 관리자만 수정 가능
        "public"."is_admin"()
    );

-- vote_requests 삭제 정책
CREATE POLICY "vote_requests_delete_policy" ON "public"."vote_requests"
    FOR DELETE USING (
        -- 관리자만 삭제 가능
        "public"."is_admin"()
    );

-- vote_request_users 테이블 RLS 활성화
ALTER TABLE "public"."vote_request_users" ENABLE ROW LEVEL SECURITY;

-- vote_request_users 읽기 정책
CREATE POLICY "vote_request_users_select_policy" ON "public"."vote_request_users"
    FOR SELECT USING (
        -- 사용자는 자신의 요청만 조회 가능
        user_id = auth.uid() OR
        -- 관리자는 모든 사용자 요청 조회 가능
        "public"."is_admin"()
    );

-- vote_request_users 생성 정책
CREATE POLICY "vote_request_users_insert_policy" ON "public"."vote_request_users"
    FOR INSERT WITH CHECK (
        -- 인증된 사용자만 자신의 요청 생성 가능
        user_id = auth.uid()
    );

-- vote_request_users 수정 정책
CREATE POLICY "vote_request_users_update_policy" ON "public"."vote_request_users"
    FOR UPDATE USING (
        -- 사용자는 자신의 요청만 수정 가능
        user_id = auth.uid() OR
        -- 관리자는 모든 요청 수정 가능
        "public"."is_admin"()
    );

-- vote_request_users 삭제 정책
CREATE POLICY "vote_request_users_delete_policy" ON "public"."vote_request_users"
    FOR DELETE USING (
        -- 사용자는 자신의 요청만 삭제 가능
        user_id = auth.uid() OR
        -- 관리자는 모든 요청 삭제 가능
        "public"."is_admin"()
    );

-- 7. 권한 부여
-- 테이블 권한
GRANT ALL ON TABLE "public"."vote_requests" TO "anon";
GRANT ALL ON TABLE "public"."vote_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."vote_requests" TO "service_role";

GRANT ALL ON TABLE "public"."vote_request_users" TO "anon";
GRANT ALL ON TABLE "public"."vote_request_users" TO "authenticated";
GRANT ALL ON TABLE "public"."vote_request_users" TO "service_role";

-- 함수 권한
GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";

GRANT ALL ON FUNCTION "public"."is_vote_request_owner"(UUID) TO "anon";
GRANT ALL ON FUNCTION "public"."is_vote_request_owner"(UUID) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_vote_request_owner"(UUID) TO "service_role";

GRANT ALL ON FUNCTION "public"."create_vote_request_with_user"(JSONB, UUID, VARCHAR) TO "anon";
GRANT ALL ON FUNCTION "public"."create_vote_request_with_user"(JSONB, UUID, VARCHAR) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_vote_request_with_user"(JSONB, UUID, VARCHAR) TO "service_role";

-- 8. 업데이트 트리거 생성 (updated_at 자동 갱신)
CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- vote_requests 테이블에 트리거 적용
CREATE TRIGGER "update_vote_requests_updated_at" 
    BEFORE UPDATE ON "public"."vote_requests" 
    FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();

-- vote_request_users 테이블에 트리거 적용
CREATE TRIGGER "update_vote_request_users_updated_at" 
    BEFORE UPDATE ON "public"."vote_request_users" 
    FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();

-- 9. 실시간 구독 설정 (선택사항)
-- ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vote_requests";
-- ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vote_request_users";

-- 마이그레이션 완료 로그
DO $$
BEGIN
    RAISE NOTICE '투표 요청(VoteRequest) 스키마 마이그레이션이 성공적으로 완료되었습니다.';
    RAISE NOTICE '테이블 생성: vote_requests, vote_request_users';
    RAISE NOTICE 'RLS 정책 적용 완료';
    RAISE NOTICE '인덱스 및 트리거 설정 완료';
END $$; 