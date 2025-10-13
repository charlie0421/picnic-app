-- Create table to log country detections per user and event source
-- Stores only ISO 3166-1 alpha-2 country code to minimize PII

create table if not exists public.user_country_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  country_code text not null check (char_length(country_code) = 2),
  source text not null default 'unknown', -- e.g., 'login', 'token_refresh', 'manual'
  created_at timestamptz not null default now()
);

create index if not exists user_country_events_user_id_created_at_idx
  on public.user_country_events (user_id, created_at desc);

alter table public.user_country_events enable row level security;

-- Allow users to read only their own events
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_country_events'
      and policyname = 'Users can select own country events'
  ) then
    create policy "Users can select own country events"
      on public.user_country_events
      for select
      using (auth.uid() = user_id);
  end if;
end $$;

-- Note: Inserts will be performed by Edge Functions using the service role key,
-- which bypasses RLS. No public insert policy is defined.



