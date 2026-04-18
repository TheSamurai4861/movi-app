import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Action = "request" | "verify" | "reset";

type RequestBody = {
  action?: Action;
  profileId?: string;
  code?: string;
  resetToken?: string;
  pin?: string;
};

type PinRecoveryRequestRow = {
  id: string;
  profile_id: string;
  created_at: string;
  consumed_at: string | null;
  code_hash: string | null;
  code_expires_at: string | null;
  attempts: number | null;
};

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

const encoder = new TextEncoder();
const recoveryCodeLifetimeMs = 15 * 60 * 1000;
const resetTokenLifetimeMs = 15 * 60 * 1000;
const recoveryCodePattern = /^\d{8}$/;
const pinPattern = /^\d{4,6}$/;
const maxVerifyAttempts = Number(Deno.env.get("PIN_RECOVERY_MAX_ATTEMPTS") ?? "5");
const brevoEndpoint = "https://api.brevo.com/v3/smtp/email";

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...corsHeaders },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asErrorMessage(error: unknown) {
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }
  return String(error ?? "Unknown error");
}

function mapError(error: unknown) {
  const message = asErrorMessage(error).toLowerCase();

  if (message.includes("expired")) {
    return { status: "expired", httpStatus: 400 };
  }
  if (message.includes("rate") || message.includes("too many") || message.includes("quota")) {
    return { status: "too_many_attempts", httpStatus: 429 };
  }
  if (
    message.includes("invalid") ||
    message.includes("token") ||
    message.includes("otp") ||
    message.includes("code")
  ) {
    return { status: "invalid", httpStatus: 400 };
  }

  return { status: "unknown", httpStatus: 500 };
}

function normalizeString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function toIsoDate(value: unknown) {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return parsed;
}

async function sha256Base64(value: string) {
  const bytes = encoder.encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return encodeBase64(new Uint8Array(digest));
}

async function derivePbkdf2Sha256(
  pin: string,
  salt: Uint8Array,
  iterations: number,
  dkLen: number,
) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(pin),
    { name: "PBKDF2" },
    false,
    ["deriveBits"],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt, iterations, hash: "SHA-256" },
    key,
    dkLen * 8,
  );
  return new Uint8Array(bits);
}

function createOpaqueResetToken() {
  const random = crypto.getRandomValues(new Uint8Array(32));
  return encodeBase64(random)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function createRecoveryCode() {
  const random = crypto.getRandomValues(new Uint32Array(1))[0] % 100000000;
  return random.toString().padStart(8, "0");
}

function parseFromAddress(raw: string) {
  const trimmed = raw.trim();
  const match = /^(.*)<([^>]+)>$/.exec(trimmed);
  if (match) {
    const name = match[1].trim().replace(/^"|"$/g, "");
    const email = match[2].trim();
    return {
      name: name || "Movi",
      email,
    };
  }

  return {
    name: "Movi",
    email: trimmed,
  };
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function buildPinRecoveryEmailHtml(code: string, expiresMinutes: number) {
  const safeCode = escapeHtml(code);
  const safeMinutes = escapeHtml(String(expiresMinutes));

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Code de recupération PIN</title>
</head>
<body style="margin:0;padding:0;background:#141414;font-family:Arial,Helvetica,sans-serif;color:#fff;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#141414;padding:28px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:460px;background:#111;border:1px solid #2a2a2a;border-radius:16px;">
          <tr>
            <td style="padding:28px 22px;text-align:center;">
              <p style="margin:0 0 8px 0;color:#2160AB;font-size:13px;letter-spacing:1.4px;text-transform:uppercase;font-weight:700;">Récupération PIN</p>
              <h1 style="margin:0 0 12px 0;font-size:24px;line-height:1.3;">Voici votre code</h1>
              <p style="margin:0 0 20px 0;color:#cfcfcf;font-size:15px;line-height:1.6;">Saisissez ce code dans l'application pour continuer.</p>
              <p style="margin:0 0 20px 0;font-size:34px;line-height:1.2;font-weight:700;letter-spacing:6px;color:#fff;">${safeCode}</p>
              <p style="margin:0;color:#b8b8b8;font-size:13px;line-height:1.6;">Ce code expire dans ${safeMinutes} minutes.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

async function sendBrevoPinRecoveryEmail(params: {
  to: string;
  code: string;
  expiresMinutes: number;
}) {
  const apiKey = normalizeString(Deno.env.get("BREVO_API_KEY"));
  const fromRaw = normalizeString(Deno.env.get("PIN_RECOVERY_EMAIL_FROM"));

  if (!apiKey || !fromRaw) {
    throw new Error("Missing BREVO_API_KEY or PIN_RECOVERY_EMAIL_FROM");
  }

  const from = parseFromAddress(fromRaw);
  const htmlContent = buildPinRecoveryEmailHtml(params.code, params.expiresMinutes);

  const response = await fetch(brevoEndpoint, {
    method: "POST",
    headers: {
      "api-key": apiKey,
      accept: "application/json",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sender: {
        email: from.email,
        name: from.name,
      },
      to: [{ email: params.to }],
      subject: "Code de récupération PIN",
      htmlContent,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Brevo error (${response.status}): ${body}`);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { status: "method_not_allowed" });
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const SUPABASE_SERVICE_ROLE_KEY =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json(500, {
      status: "not_available",
      message: "Missing Supabase env vars.",
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  const user = userData?.user;
  const userId = user?.id;
  const email = normalizeString(user?.email);

  if (userErr || !userId) {
    return json(401, { status: "unauthorized" });
  }
  if (!email) {
    return json(400, {
      status: "not_available",
      message: "Current user has no email.",
    });
  }

  let body: RequestBody;
  try {
    const parsed = await req.json();
    if (!isRecord(parsed)) {
      return json(400, { status: "invalid", message: "Invalid JSON body." });
    }
    body = parsed as RequestBody;
  } catch {
    return json(400, { status: "invalid", message: "Invalid JSON body." });
  }

  const action = body.action;
  if (action !== "request" && action !== "verify" && action !== "reset") {
    return json(400, { status: "unsupported_action" });
  }

  if (action === "request") {
    const profileId = normalizeString(body.profileId);
    if (!profileId) {
      return json(400, { status: "missing_profile" });
    }

    const { data: profile, error: profileErr } = await serviceClient
      .from("profiles")
      .select("id, account_id")
      .eq("id", profileId)
      .maybeSingle();

    if (profileErr || !profile) {
      return json(404, { status: "not_found", message: "Profile not found." });
    }
    if (profile.account_id !== userId) {
      return json(403, { status: "forbidden" });
    }

    const { error: deleteErr } = await serviceClient
      .from("profile_pin_recovery_requests")
      .delete()
      .eq("account_id", userId)
      .is("consumed_at", null);

    if (deleteErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to prepare recovery request.",
      });
    }

    const code = createRecoveryCode();
    const codeHash = await sha256Base64(code);
    const codeExpiresAt = new Date(Date.now() + recoveryCodeLifetimeMs).toISOString();

    const { error: insertErr } = await serviceClient
      .from("profile_pin_recovery_requests")
      .insert({
        account_id: userId,
        profile_id: profileId,
        email,
        code_hash: codeHash,
        code_expires_at: codeExpiresAt,
        attempts: 0,
      });

    if (insertErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to persist recovery request.",
      });
    }

    try {
      await sendBrevoPinRecoveryEmail({
        to: email,
        code,
        expiresMinutes: Math.floor(recoveryCodeLifetimeMs / 60000),
      });
    } catch (sendErr) {
      await serviceClient
        .from("profile_pin_recovery_requests")
        .delete()
        .eq("account_id", userId)
        .eq("profile_id", profileId)
        .is("consumed_at", null);

      const mapped = mapError(sendErr);
      return json(mapped.httpStatus, {
        status: mapped.status,
        message: asErrorMessage(sendErr),
      });
    }

    return json(200, { status: "code_sent" });
  }

  if (action === "verify") {
    const code = normalizeString(body.code);
    if (!recoveryCodePattern.test(code)) {
      return json(400, { status: "invalid_code" });
    }

    const { data: requestRow, error: requestErr } = await serviceClient
      .from("profile_pin_recovery_requests")
      .select("id, profile_id, created_at, consumed_at, code_hash, code_expires_at, attempts")
      .eq("account_id", userId)
      .is("consumed_at", null)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle<PinRecoveryRequestRow>();

    if (requestErr || !requestRow) {
      return json(400, {
        status: "invalid",
        message: "No active recovery request.",
      });
    }

    const expiresAt = toIsoDate(requestRow.code_expires_at);
    if (!expiresAt || expiresAt.getTime() <= Date.now()) {
      await serviceClient
        .from("profile_pin_recovery_requests")
        .update({ consumed_at: new Date().toISOString() })
        .eq("id", requestRow.id);
      return json(400, { status: "expired" });
    }

    const attempts = requestRow.attempts ?? 0;
    if (attempts >= maxVerifyAttempts) {
      return json(429, { status: "too_many_attempts" });
    }

    const codeHash = await sha256Base64(code);
    if (requestRow.code_hash !== codeHash) {
      const nextAttempts = attempts + 1;
      await serviceClient
        .from("profile_pin_recovery_requests")
        .update({ attempts: nextAttempts })
        .eq("id", requestRow.id);

      if (nextAttempts >= maxVerifyAttempts) {
        return json(429, { status: "too_many_attempts" });
      }
      return json(400, { status: "invalid" });
    }

    const resetToken = createOpaqueResetToken();
    const resetTokenHash = await sha256Base64(resetToken);
    const tokenExpiresAt = new Date(Date.now() + resetTokenLifetimeMs).toISOString();

    const { error: revokeTokensErr } = await serviceClient
      .from("profile_pin_recovery_tokens")
      .delete()
      .eq("account_id", userId)
      .eq("profile_id", requestRow.profile_id)
      .is("consumed_at", null);

    if (revokeTokensErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to rotate recovery token.",
      });
    }

    const { error: tokenErr } = await serviceClient
      .from("profile_pin_recovery_tokens")
      .insert({
        account_id: userId,
        profile_id: requestRow.profile_id,
        token_hash: resetTokenHash,
        expires_at: tokenExpiresAt,
      });

    if (tokenErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to persist recovery token.",
      });
    }

    const { error: consumeErr } = await serviceClient
      .from("profile_pin_recovery_requests")
      .update({ consumed_at: new Date().toISOString() })
      .eq("id", requestRow.id);

    if (consumeErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to finalize recovery verification.",
      });
    }

    return json(200, { status: "verified", resetToken });
  }

  const resetToken = normalizeString(body.resetToken);
  const pin = normalizeString(body.pin);

  if (!resetToken) {
    return json(400, { status: "missing_token" });
  }
  if (!pinPattern.test(pin)) {
    return json(400, { status: "invalid_pin" });
  }

  const resetTokenHash = await sha256Base64(resetToken);
  const { data: tokenRow, error: tokenLookupErr } = await serviceClient
    .from("profile_pin_recovery_tokens")
    .select("id, account_id, profile_id, expires_at, consumed_at")
    .eq("token_hash", resetTokenHash)
    .maybeSingle();

  if (tokenLookupErr || !tokenRow || tokenRow.account_id !== userId) {
    return json(400, { status: "invalid_token" });
  }
  if (tokenRow.consumed_at) {
    return json(400, { status: "expired_token" });
  }

  const expiresAt = toIsoDate(tokenRow.expires_at);
  if (!expiresAt || expiresAt.getTime() <= Date.now()) {
    await serviceClient
      .from("profile_pin_recovery_tokens")
      .update({ consumed_at: new Date().toISOString() })
      .eq("id", tokenRow.id);
    return json(400, { status: "expired_token" });
  }

  const iterations = Number(
    Deno.env.get("PIN_PBKDF2_ITERATIONS") ?? "210000",
  );
  const dkLen = 32;
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const hash = await derivePbkdf2Sha256(pin, salt, iterations, dkLen);

  const { error: upsertErr } = await serviceClient
    .from("profile_pin_secrets")
    .upsert(
      {
        profile_id: tokenRow.profile_id,
        account_id: userId,
        pin_salt: encodeBase64(salt),
        pin_hash: encodeBase64(hash),
        algo: "pbkdf2_sha256",
        params: { iterations, dkLen },
        updated_at: new Date().toISOString(),
      },
      { onConflict: "profile_id" },
    );

  if (upsertErr) {
    return json(500, { status: "unknown", message: "Failed to store PIN." });
  }

  const { error: flagErr } = await serviceClient
    .from("profiles")
    .update({ has_pin: true })
    .eq("id", tokenRow.profile_id)
    .eq("account_id", userId);

  if (flagErr) {
    return json(500, {
      status: "unknown",
      message: "Failed to update profile.has_pin.",
    });
  }

  const { error: consumeErr } = await serviceClient
    .from("profile_pin_recovery_tokens")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", tokenRow.id);

  if (consumeErr) {
    return json(500, {
      status: "unknown",
      message: "Failed to finalize PIN reset.",
    });
  }

  return json(200, { status: "reset_success" });
});
