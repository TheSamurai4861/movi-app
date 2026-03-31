-- Movi: Premium entitlements (server source of truth)
-- Date: 2026-03-31

create table if not exists public.subscription_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  product_id text not null,
  status text not null check (status in ('active', 'inactive', 'expired', 'grace', 'revoked')),
  entitlements jsonb not null default '{}'::jsonb,
  active_plan_id text null,
  expires_at timestamptz null,
  last_verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subscription_entitlements_user_id_idx
  on public.subscription_entitlements(user_id);

create index if not exists subscription_entitlements_user_platform_idx
  on public.subscription_entitlements(user_id, platform);

create index if not exists subscription_entitlements_expires_at_idx
  on public.subscription_entitlements(expires_at);

-- Needed for `upsert(..., { onConflict: "user_id,platform" })`
create unique index if not exists subscription_entitlements_user_platform_uniq
  on public.subscription_entitlements(user_id, platform);

-- Keep updated_at current
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_subscription_entitlements_updated_at
  on public.subscription_entitlements;

create trigger trg_subscription_entitlements_updated_at
before update on public.subscription_entitlements
for each row execute function public.set_updated_at();

alter table public.subscription_entitlements enable row level security;

-- RLS: user can read own entitlements
drop policy if exists "read_own_entitlements"
  on public.subscription_entitlements;

create policy "read_own_entitlements"
  on public.subscription_entitlements
  for select
  using (auth.uid() = user_id);

-- RLS: block client writes (only service role / edge functions)
drop policy if exists "no_client_writes_entitlements"
  on public.subscription_entitlements;

create policy "no_client_writes_entitlements"
  on public.subscription_entitlements
  for all
  using (false)
  with check (false);

