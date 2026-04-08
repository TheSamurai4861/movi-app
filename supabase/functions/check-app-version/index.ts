import { createClient } from 'npm:@supabase/supabase-js@2'

interface VersionCheckRequest {
  appId: string
  environment: string
  appVersion: string
  buildNumber: string
  platform: string
  osVersion?: string
}

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

const defaultCacheTtlSeconds = 21600
const desktopPlatforms = new Set(['windows', 'macos', 'linux'])

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
    .rpc('get_app_version_policy', {
      p_app_id: payload.appId,
      p_environment: payload.environment,
      p_platform: payload.platform,
    })
    .maybeSingle<VersionPolicyRow>()

  if (error) {
    console.error('[check-app-version] policy lookup failed', {
      message: error.message,
      details: 'details' in error ? error.details : undefined,
      hint: 'hint' in error ? error.hint : undefined,
      code: 'code' in error ? error.code : undefined,
      appId: payload.appId,
      environment: payload.environment,
      platform: payload.platform,
    })

    return response(500, {
      error: 'policy_lookup_failed',
      reasonCode: 'policy_lookup_failed',
    })
  }

  if (!data) {
    return buildNoPolicyResponse(payload)
  }

  const currentVersion = normalizeVersion(payload.appVersion)
  const minSupportedVersion = normalizeVersion(data.min_supported_version)
  const latestVersion = data.latest_version ? normalizeVersion(data.latest_version) : null
  const cacheTtlSeconds = positiveTtl(data.cache_ttl_seconds)

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
      cacheTtlSeconds,
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
      cacheTtlSeconds,
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
      cacheTtlSeconds,
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
    cacheTtlSeconds,
  })
})

function buildNoPolicyResponse(payload: VersionCheckRequest) {
  const currentVersion = normalizeVersion(payload.appVersion)

  if (desktopPlatforms.has(payload.platform)) {
    return response(200, {
      status: 'allowed',
      reasonCode: 'policy_not_found_desktop_allowed',
      currentVersion,
      minSupportedVersion: currentVersion,
      latestVersion: null,
      platform: payload.platform,
      updateUrl: null,
      cacheTtlSeconds: 3600,
    })
  }

  return response(200, {
    status: 'allowed',
    reasonCode: 'policy_not_found',
    currentVersion,
    minSupportedVersion: currentVersion,
    latestVersion: null,
    platform: payload.platform,
    updateUrl: null,
    cacheTtlSeconds: 3600,
  })
}

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
  const appId = normalizeIdentifier(readRequiredString(source.appId))
  const environment = normalizeIdentifier(readRequiredString(source.environment))
  const appVersion = readRequiredString(source.appVersion)
  const buildNumber = readRequiredString(source.buildNumber)
  const platform = normalizePlatform(readRequiredString(source.platform))
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

function normalizeIdentifier(value: string | null): string | null {
  if (!value) return null
  const normalized = value.trim().toLowerCase()
  return normalized.length > 0 ? normalized : null
}

function normalizePlatform(value: string | null): string | null {
  if (!value) return null

  const normalized = value.trim().toLowerCase()

  switch (normalized) {
    case 'win32':
    case 'win':
      return 'windows'
    case 'osx':
      return 'macos'
    default:
      return normalized.length > 0 ? normalized : null
  }
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
    return defaultCacheTtlSeconds
  }

  return Math.floor(value)
}
