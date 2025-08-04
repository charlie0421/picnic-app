
-- Q&A 첨부파일을 위한 스토리지 버킷 생성
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('qna_attachments', 'qna_attachments', FALSE, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 스토리지 RLS 정책

-- NOTE: 기존의 한글 정책 이름이 너무 길어 DB에서 잘리는 문제가 발생하여 영문으로 변경하고, 여러번 실행 가능하도록 수정합니다.
-- 기존 정책들을 먼저 삭제합니다.
DROP POLICY IF EXISTS "사용자는 qna_attachments 버킷의 파일을 볼 수 있습니다" ON storage.objects;
DROP POLICY IF EXISTS "사용자는 자신의 경로에 파일을 업로드할 수 있습니다" ON storage.objects;
DROP POLICY IF EXISTS "사용자는 자신의 파일만 수정할 수 있습니다" ON storage.objects;
DROP POLICY IF EXISTS "사용자는 자신의 파일만 삭제할 수 있습니다" ON storage.objects;
-- 이름이 잘렸을 경우를 대비하여 잘린 이름으로도 삭제 시도
DROP POLICY IF EXISTS "사용자는 qna_attachments 버킷의 파일을 볼 수 있습" ON storage.objects;


-- 1. Select policy for qna_attachments
DROP POLICY IF EXISTS "qna_attachments_select_policy" ON storage.objects;
CREATE POLICY "qna_attachments_select_policy"
ON storage.objects FOR SELECT
USING ( bucket_id = 'qna_attachments' );

-- 2. Insert policy for qna_attachments
DROP POLICY IF EXISTS "qna_attachments_insert_policy" ON storage.objects;
--    파일 경로는 '{user_id}/{thread_id}/{file_name}' 형식을 따릅니다.
CREATE POLICY "qna_attachments_insert_policy"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'qna_attachments' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

-- 3. Update policy for qna_attachments
DROP POLICY IF EXISTS "qna_attachments_update_policy" ON storage.objects;
CREATE POLICY "qna_attachments_update_policy"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'qna_attachments' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

-- 4. Delete policy for qna_attachments
DROP POLICY IF EXISTS "qna_attachments_delete_policy" ON storage.objects;
CREATE POLICY "qna_attachments_delete_policy"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'qna_attachments' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

-- 관리자 정책 (필요시 추가)
-- 예: CREATE POLICY "관리자는 모든 파일을 볼 수 있습니다" ON storage.objects FOR SELECT USING (is_admin()); 