import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment breakdown migration preserves its admin aggregation contract', () {
    final migration = File(
      '../supabase/migrations/20260803085209_cast_payment_breakdown_revenue_to_text.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('CREATE OR REPLACE FUNCTION public.get_payment_breakdown('),
    );
    expect(migration, contains('IF NOT public.is_super_admin() THEN'));
    expect(
      migration,
      contains("IF p_dimension NOT IN ('platform', 'product') THEN"),
    );
    expect(migration, contains("rc.status = 'valid'"));
    expect(migration, contains("rc.environment = 'production'"));
    expect(
      migration,
      contains('(p_start IS NULL OR rc.created_at >= p_start)'),
    );
    expect(migration, contains('(p_end   IS NULL OR rc.created_at <  p_end)'));
    expect(
      migration,
      contains('COUNT(*)::bigint                     AS pay_cnt'),
    );
    expect(
      migration,
      contains('COALESCE(SUM(pr.price::numeric), 0)  AS revenue_usd'),
    );
    expect(
      migration,
      contains(
        "jsonb_build_object('key', key, 'pay_cnt', pay_cnt, 'revenue_usd', revenue_usd::text)",
      ),
    );
  });
}
