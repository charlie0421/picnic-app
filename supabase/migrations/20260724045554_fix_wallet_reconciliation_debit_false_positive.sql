-- A successful DEBIT (for example general_vote_v3) has vote/debit evidence,
-- not wallet_credit_operations rows. The original reconciliation predicate
-- treated every non-Cotton operation as a CREDIT and raised a false CRITICAL
-- violation, which then blocked all Cotton issuance.
do $migration$
declare
  v_definition text;
  v_old text :=
    'or (f.source_type<>''cotton_ad_grant'' and (';
  v_new text :=
    'or (f.operation_kind=''CREDIT'' and f.source_type<>''cotton_ad_grant'' and (';
begin
  select pg_get_functiondef(p.oid)
    into strict v_definition
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'wallet_private'
     and p.proname = 'reconcile_wallet_batch'
     and p.prokind = 'f';

  if position(v_new in v_definition) > 0 then
    return;
  end if;
  if position(v_old in v_definition) = 0 then
    raise exception using
      errcode = 'P0001',
      message = 'WALLET_RECONCILIATION_PREDICATE_NOT_FOUND';
  end if;

  execute replace(v_definition, v_old, v_new);
end
$migration$;

-- Migration-time regression guard: never let a DEBIT operation enter the
-- credit-allocation evidence branch again.
do $test$
declare
  v_definition text;
begin
  select pg_get_functiondef(p.oid)
    into strict v_definition
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'wallet_private'
     and p.proname = 'reconcile_wallet_batch'
     and p.prokind = 'f';

  if position(
    'f.operation_kind=''CREDIT'' and f.source_type<>''cotton_ad_grant'''
    in v_definition
  ) = 0 then
    raise exception using
      errcode = 'P0001',
      message = 'WALLET_RECONCILIATION_DEBIT_FALSE_POSITIVE_NOT_FIXED';
  end if;
end
$test$;
