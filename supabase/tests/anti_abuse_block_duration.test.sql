begin;

create extension if not exists pgtap with schema extensions;

set local search_path = public, extensions;

select plan(5);

insert into public.ip_block_decisions (
  ip_hash,
  action_type,
  decision,
  mode,
  reason,
  applied_window,
  threshold_used,
  observed_value,
  expires_at
)
values (
  'pgtap-block-duration',
  'test_action',
  'blocked',
  'enforce',
  'test_reason',
  3600,
  10,
  11,
  statement_timestamp() + interval '24 hours'
);

select ok(
  expires_at between statement_timestamp() + interval '47 hours 59 minutes'
                 and statement_timestamp() + interval '48 hours 1 minute',
  'automatic blocked decisions expire after 48 hours'
)
from public.ip_block_decisions
where ip_hash = 'pgtap-block-duration';

insert into public.ip_block_decisions (
  ip_hash,
  action_type,
  decision,
  mode,
  reason,
  applied_window,
  threshold_used,
  observed_value,
  expires_at
)
values (
  'pgtap-suspect-duration',
  'test_action',
  'suspect',
  'shadow',
  'test_reason',
  3600,
  10,
  10,
  null
);

select is(
  expires_at,
  null::timestamptz,
  'suspect decisions remain non-expiring'
)
from public.ip_block_decisions
where ip_hash = 'pgtap-suspect-duration';

insert into public.ip_block_decisions (
  ip_hash,
  action_type,
  decision,
  mode,
  reason,
  applied_window,
  threshold_used,
  observed_value,
  expires_at
)
values (
  'pgtap-long-block-duration',
  'test_action',
  'blocked',
  'enforce',
  'test_reason',
  3600,
  10,
  11,
  statement_timestamp() + interval '72 hours'
);

select ok(
  expires_at between statement_timestamp() + interval '71 hours 59 minutes'
                 and statement_timestamp() + interval '72 hours 1 minute',
  'blocks longer than 48 hours are not shortened'
)
from public.ip_block_decisions
where ip_hash = 'pgtap-long-block-duration';

insert into public.ip_block_decisions (
  ip_hash,
  action_type,
  decision,
  mode,
  reason,
  applied_window,
  threshold_used,
  observed_value,
  expires_at
)
values (
  'pgtap-permanent-block-duration',
  'test_action',
  'blocked',
  'enforce',
  'test_reason',
  3600,
  10,
  11,
  null
);

select is(
  expires_at,
  null::timestamptz,
  'permanent blocks remain non-expiring'
)
from public.ip_block_decisions
where ip_hash = 'pgtap-permanent-block-duration';

alter table public.ip_block_decisions
  disable trigger enforce_anti_abuse_block_expiry;

insert into public.ip_block_decisions (
  ip_hash,
  action_type,
  decision,
  mode,
  reason,
  applied_window,
  threshold_used,
  observed_value,
  expires_at
)
values (
  'pgtap-existing-block-duration',
  'test_action',
  'blocked',
  'enforce',
  'test_reason',
  3600,
  10,
  11,
  statement_timestamp() + interval '2 hours'
);

alter table public.ip_block_decisions
  enable trigger enforce_anti_abuse_block_expiry;

update public.ip_block_decisions
set attempt_count = attempt_count + 1
where ip_hash = 'pgtap-existing-block-duration';

select ok(
  expires_at between statement_timestamp() + interval '1 hour 59 minutes'
                 and statement_timestamp() + interval '2 hours 1 minute',
  'pre-existing blocks are not extended by later updates'
)
from public.ip_block_decisions
where ip_hash = 'pgtap-existing-block-duration';

select * from finish();

rollback;
