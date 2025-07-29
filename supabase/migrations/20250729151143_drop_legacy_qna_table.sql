-- Description: Drop the legacy qnas table as it is no longer used.

DROP TABLE IF EXISTS public.qnas CASCADE;

COMMENT ON TABLE public.qnas IS 'This table is obsolete and has been replaced by qna_threads, qna_messages, and qna_attachments tables.';
