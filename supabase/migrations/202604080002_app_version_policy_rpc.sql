create or replace function public.get_app_version_policy(
  p_app_id text,
  p_environment text,
  p_platform text
)
returns table (
  app_id text,
  environment text,
  platform text,
  min_supported_version text,
  latest_version text,
  min_os_version text,
  update_url text,
  force_message text,
  soft_message text,
  cache_ttl_seconds integer,
  is_enabled boolean
)
language sql
security definer
set search_path = public, private
as $$
  select
    p.app_id,
    p.environment,
    p.platform,
    p.min_supported_version,
    p.latest_version,
    p.min_os_version,
    p.update_url,
    p.force_message,
    p.soft_message,
    p.cache_ttl_seconds,
    p.is_enabled
  from private.app_version_policies as p
  where p.app_id = p_app_id
    and p.environment = p_environment
    and p.platform = p_platform
    and p.is_enabled = true
  limit 1;
$$;

revoke all on function public.get_app_version_policy(text, text, text) from public;
revoke all on function public.get_app_version_policy(text, text, text) from anon;
revoke all on function public.get_app_version_policy(text, text, text) from authenticated;

grant execute on function public.get_app_version_policy(text, text, text) to service_role;
