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

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

const encoder = new TextEncoder();
const recoveryRequestLifetimeMs = 60 * 60 * 1000;
const resetTokenLifetimeMs = 15 * 60 * 1000;
const recoveryCodePattern = /^\d{8}$/;
const pinPattern = /^\d{4,6}$/;

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

function mapAuthError(error: unknown) {
  const message = asErrorMessage(error).toLowerCase();

  if (message.includes("expired")) {
    return { status: "expired", httpStatus: 400 };
  }
  if (message.includes("rate") || message.includes("too many")) {
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
  const publicClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
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

    const { error: insertErr } = await serviceClient
      .from("profile_pin_recovery_requests")
      .insert({
        account_id: userId,
        profile_id: profileId,
        email,
      });

    if (insertErr) {
      return json(500, {
        status: "unknown",
        message: "Failed to persist recovery request.",
      });
    }

    const { error: resetErr } = await publicClient.auth.resetPasswordForEmail(
      email,
    );
    if (resetErr) {
      await serviceClient
        .from("profile_pin_recovery_requests")
        .delete()
        .eq("account_id", userId)
        .eq("profile_id", profileId)
        .is("consumed_at", null);

      const mapped = mapAuthError(resetErr);
      return json(mapped.httpStatus, {
        status: mapped.status,
        message: asErrorMessage(resetErr),
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
      .select("id, profile_id, email, created_at, consumed_at")
      .eq("account_id", userId)
      .is("consumed_at", null)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (requestErr || !requestRow) {
      return json(400, {
        status: "invalid",
        message: "No active recovery request.",
      });
    }

    const requestCreatedAt = toIsoDate(requestRow.created_at);
    if (
      !requestCreatedAt ||
      Date.now() - requestCreatedAt.getTime() > recoveryRequestLifetimeMs
    ) {
      await serviceClient
        .from("profile_pin_recovery_requests")
        .update({ consumed_at: new Date().toISOString() })
        .eq("id", requestRow.id);
      return json(400, { status: "expired" });
    }

    const { error: verifyErr } = await publicClient.auth.verifyOtp({
      email: requestRow.email,
      token: code,
      type: "recovery",
    });

    if (verifyErr) {
      const mapped = mapAuthError(verifyErr);
      return json(mapped.httpStatus, {
        status: mapped.status,
        message: asErrorMessage(verifyErr),
      });
    }

    const resetToken = createOpaqueResetToken();
    const resetTokenHash = await sha256Base64(resetToken);
    const expiresAt = new Date(Date.now() + resetTokenLifetimeMs).toISOString();

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
        expires_at: expiresAt,
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
