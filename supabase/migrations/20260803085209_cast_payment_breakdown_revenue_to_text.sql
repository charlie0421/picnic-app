CREATE OR REPLACE FUNCTION public.get_payment_breakdown(
  p_start     timestamptz DEFAULT NULL,
  p_end       timestamptz DEFAULT NULL,
  p_dimension text        DEFAULT 'platform'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'permission denied: admin only' USING ERRCODE = '42501';
  END IF;
  IF p_dimension NOT IN ('platform', 'product') THEN
    RAISE EXCEPTION 'invalid dimension: %', p_dimension USING ERRCODE = '22023';
  END IF;

  SELECT COALESCE(jsonb_agg(
           jsonb_build_object('key', key, 'pay_cnt', pay_cnt, 'revenue_usd', revenue_usd::text)
           ORDER BY revenue_usd DESC, key
         ), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT CASE p_dimension
             WHEN 'platform' THEN rc.platform
             ELSE COALESCE(pr.product_name, pr.id::text)
           END                                 AS key,
           COUNT(*)::bigint                     AS pay_cnt,
           COALESCE(SUM(pr.price::numeric), 0)  AS revenue_usd
    FROM public.receipts rc
    JOIN public.products pr ON pr.id = rc.product_id
    WHERE rc.status = 'valid'
      AND rc.environment = 'production'
      AND (p_start IS NULL OR rc.created_at >= p_start)
      AND (p_end   IS NULL OR rc.created_at <  p_end)
    GROUP BY 1
  ) t;

  RETURN v_result;
END;
$$;
