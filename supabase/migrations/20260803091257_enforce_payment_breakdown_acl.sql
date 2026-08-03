REVOKE EXECUTE ON FUNCTION public.get_payment_breakdown(timestamptz, timestamptz, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_payment_breakdown(timestamptz, timestamptz, text) TO authenticated;
