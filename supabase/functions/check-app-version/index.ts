import { createClient } from 'npm:@supabase/supabase-js@2'

interface VersionCheckRequest {
  appId: string
  environment: string
  appVersion: string
  buildNumber: string
  platform: string
  osVersion?: string
}

type VersionStatus = 'allowed' | 'soft_update' | 'force_update'

interface VersionPolicyRow {
  app_id: string
  environment: string
  platform: string
  min_supported_version: string
  latest_version: string | null
  min_os_version: string | null
  update_url: string | null
  force_message: string | null
  soft_message: string | null
  cache_ttl_seconds: number | null
  is_enabled: boolean
}

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'method_not_allowed' }),
      { status: 405, headers: jsonHeaders },
    )
  }

  let body: unknown
  try {
    body = await request.json()
  } catch {
    return response(400, { error: 'invalid_json', reasonCode: 'invalid_json' })
  }

  const payload = validatePayload(body)
  if ('error' in payload) {
    return response(400, payload)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !serviceRoleKey) {
    return response(500, {
      error: 'server_not_configured',
      reasonCode: 'server_not_configured',
    })
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)

  const { data, error } = await supabase
    .schema('private')
    .from('app_version_policies')
    .select('app_id, environment, platform, min_supported_version, latest_version, min_os_version, update_url, force_message, soft_message, cache_ttl_seconds, is_enabled')
    .eq('app_id', payload.appId)
    .eq('environment', payload.environment)
    .eq('platform', payload.platform)
    .eq('is_enabled', true)
    .maybeSingle<VersionPolicyRow>()

  if (error) {
    console.error('[check-app-version] policy lookup failed', error)
    return response(500, {
      error: 'policy_lookup_failed',
      reasonCode: 'policy_lookup_failed',
    })
  }

  if (!data) {
    return response(404, {
      error: 'policy_not_found',
      reasonCode: 'policy_not_found',
    })
  }

  const currentVersion = normalizeVersion(payload.appVersion)
  const minSupportedVersion = normalizeVersion(data.min_supported_version)
  const latestVersion = data.latest_version ? normalizeVersion(data.latest_version) : null

  if (compareVersions(currentVersion, minSupportedVersion) < 0) {
    return response(200, {
      status: 'force_update',
      reasonCode: 'min_supported_version_not_met',
      currentVersion,
      minSupportedVersion,
      latestVersion,
      platform: payload.platform,
      updateUrl: data.update_url,
      message:
        data.force_message ??
        'A newer version of the application is required to continue.',
      cacheTtlSeconds: positiveTtl(data.cache_ttl_seconds),
    })
  }

  if (
    data.min_os_version &&
    payload.osVersion &&
    compareVersions(normalizeVersion(payload.osVersion), normalizeVersion(data.min_os_version)) < 0
  ) {
    return response(200, {
      status: 'force_update',
      reasonCode: 'minimum_os_version_not_met',
      currentVersion,
      minSupportedVersion,
      latestVersion,
      platform: payload.platform,
      updateUrl: data.update_url,
      message:
        data.force_message ??
        'Your device operating system is no longer supported by this version.',
      cacheTtlSeconds: positiveTtl(data.cache_ttl_seconds),
    })
  }

  if (latestVersion && compareVersions(currentVersion, latestVersion) < 0) {
    return response(200, {
      status: 'soft_update',
      reasonCode: 'latest_version_available',
      currentVersion,
      minSupportedVersion,
      latestVersion,
      platform: payload.platform,
      updateUrl: data.update_url,
      message:
        data.soft_message ??
        'A newer version is available.',
      cacheTtlSeconds: positiveTtl(data.cache_ttl_seconds),
    })
  }

  return response(200, {
    status: 'allowed',
    reasonCode: 'app_update_allowed',
    currentVersion,
    minSupportedVersion,
    latestVersion,
    platform: payload.platform,
    updateUrl: data.update_url,
    cacheTtlSeconds: positiveTtl(data.cache_ttl_seconds),
  })
})

function response(status: number, payload: Record<string, unknown>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: jsonHeaders,
  })
}

function validatePayload(input: unknown): VersionCheckRequest | Record<string, string> {
  if (!input || typeof input !== 'object') {
    return { error: 'invalid_payload', reasonCode: 'invalid_payload' }
  }

  const source = input as Record<string, unknown>
  const appId = readRequiredString(source.appId)
  const environment = readRequiredString(source.environment)
  const appVersion = readRequiredString(source.appVersion)
  const buildNumber = readRequiredString(source.buildNumber)
  const platform = readRequiredString(source.platform)
  const osVersion = readOptionalString(source.osVersion)

  if (!appId || !environment || !appVersion || !buildNumber || !platform) {
    return { error: 'invalid_payload', reasonCode: 'invalid_payload' }
  }

  return {
    appId,
    environment,
    appVersion,
    buildNumber,
    platform,
    osVersion,
  }
}

function readRequiredString(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : null
}

function readOptionalString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : undefined
}

function normalizeVersion(raw: string): string {
  const trimmed = raw.trim()
  if (!trimmed) {
    return '0.0.0'
  }

  const match = trimmed.match(/[0-9]+(?:\.[0-9]+)*/)
  return match?.[0] ?? '0.0.0'
}

function compareVersions(left: string, right: string): number {
  const leftParts = left.split('.').map((value) => Number.parseInt(value, 10) || 0)
  const rightParts = right.split('.').map((value) => Number.parseInt(value, 10) || 0)
  const size = Math.max(leftParts.length, rightParts.length)

  for (let index = 0; index < size; index += 1) {
    const leftValue = leftParts[index] ?? 0
    const rightValue = rightParts[index] ?? 0
    if (leftValue > rightValue) return 1
    if (leftValue < rightValue) return -1
  }

  return 0
}

function positiveTtl(value: number | null): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
    return 21600
  }

  return Math.floor(value)
}
