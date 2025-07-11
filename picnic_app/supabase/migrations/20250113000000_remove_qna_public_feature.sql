-- Migration: Remove public/private feature from QnA
-- Created: 2025-01-13
-- Description: Remove is_private column from qnas table since public questions are no longer supported

-- Check and drop dependent views first
DROP VIEW IF EXISTS qnas_active CASCADE;

-- Drop any other views that might depend on is_private column
-- (Add more DROP VIEW statements here if there are other dependent views)

-- Drop the is_private column from qnas table
ALTER TABLE qnas DROP COLUMN IF EXISTS is_private;

-- Recreate qnas_active view without is_private column (if it was needed)
-- CREATE VIEW qnas_active AS
-- SELECT * FROM qnas WHERE deleted_at IS NULL;
-- (Uncomment and modify above if qnas_active view is still needed)

-- Add comment to document the change
COMMENT ON TABLE qnas IS 'QnA table without public/private distinction - all QnAs are private by default'; 