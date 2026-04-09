create extension if not exists pgcrypto;

alter table if exists public.profiles
  add column if not exists has_pin boolean not null default false;

create table if not exists public.profile_pin_recovery_requests (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references auth.users (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  email text not null,
  created_at timestamptz not null default timezone('utc', now()),
  consumed_at timestamptz null
);

create table if not exists public.profile_pin_recovery_tokens (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references auth.users (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  token_hash text not null,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null,
  consumed_at timestamptz null
);

create table if not exists public.profile_pin_secrets (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  account_id uuid not null references auth.users (id) on delete cascade,
  pin_salt text not null,
  pin_hash text not null,
  algo text not null,
  params jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists profile_pin_recovery_requests_account_idx
  on public.profile_pin_recovery_requests (account_id, created_at desc);

create index if not exists profile_pin_recovery_requests_profile_idx
  on public.profile_pin_recovery_requests (profile_id, created_at desc);

create unique index if not exists profile_pin_recovery_requests_active_account_idx
  on public.profile_pin_recovery_requests (account_id)
  where consumed_at is null;

create unique index if not exists profile_pin_recovery_tokens_token_hash_idx
  on public.profile_pin_recovery_tokens (token_hash);

create unique index if not exists profile_pin_recovery_tokens_active_profile_idx
  on public.profile_pin_recovery_tokens (account_id, profile_id)
  where consumed_at is null;

alter table public.profile_pin_recovery_requests enable row level security;
alter table public.profile_pin_recovery_tokens enable row level security;
alter table public.profile_pin_secrets enable row level security;
