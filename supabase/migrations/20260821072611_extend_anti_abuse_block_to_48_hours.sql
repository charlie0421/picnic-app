create or replace function public.enforce_anti_abuse_block_expiry()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  if new.decision = 'blocked'
     and new.expires_at is not null
     and new.expires_at < statement_timestamp() + interval '48 hours' then
    new.expires_at := statement_timestamp() + interval '48 hours';
  end if;

  return new;
end;
$function$;

comment on function public.enforce_anti_abuse_block_expiry() is
  'Ensures newly inserted, expiring anti-abuse blocks last at least 48 hours.';

revoke execute on function public.enforce_anti_abuse_block_expiry() from public;
revoke execute on function public.enforce_anti_abuse_block_expiry() from anon;
revoke execute on function public.enforce_anti_abuse_block_expiry() from authenticated;

drop trigger if exists enforce_anti_abuse_block_expiry
  on public.ip_block_decisions;

create trigger enforce_anti_abuse_block_expiry
before insert on public.ip_block_decisions
for each row
execute function public.enforce_anti_abuse_block_expiry();
