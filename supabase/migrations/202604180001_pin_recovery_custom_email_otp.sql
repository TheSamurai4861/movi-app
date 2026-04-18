alter table public.profile_pin_recovery_requests
  add column if not exists code_hash text,
  add column if not exists code_expires_at timestamptz,
  add column if not exists attempts integer not null default 0;

alter table public.profile_pin_recovery_requests
  drop constraint if exists profile_pin_recovery_requests_attempts_non_negative;

alter table public.profile_pin_recovery_requests
  add constraint profile_pin_recovery_requests_attempts_non_negative
  check (attempts >= 0);

create index if not exists profile_pin_recovery_requests_code_exp_idx
  on public.profile_pin_recovery_requests (account_id, code_expires_at desc)
  where consumed_at is null;
