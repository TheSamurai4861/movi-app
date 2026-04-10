insert into private.app_version_policies (
  app_id,
  environment,
  platform,
  min_supported_version,
  latest_version,
  min_os_version,
  update_url,
  force_message,
  soft_message,
  cache_ttl_seconds,
  is_enabled
)
values
  (
    'movi',
    'prod',
    'windows',
    '1.0.3',
    '1.0.3',
    null,
    null,
    'Une mise a jour est requise pour continuer.',
    'Une version plus recente est disponible.',
    21600,
    true
  )
on conflict (app_id, environment, platform)
do update set
  min_supported_version = excluded.min_supported_version,
  latest_version = excluded.latest_version,
  min_os_version = excluded.min_os_version,
  update_url = excluded.update_url,
  force_message = excluded.force_message,
  soft_message = excluded.soft_message,
  cache_ttl_seconds = excluded.cache_ttl_seconds,
  is_enabled = excluded.is_enabled,
  updated_at = timezone('utc', now());
